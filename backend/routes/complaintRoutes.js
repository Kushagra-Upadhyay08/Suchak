const express = require('express');
const router = express.Router();
const Complaint = require('../models/Complaint');
const { verifyJWT, checkRole } = require('../middleware/auth');
const { calculateDistance } = require('../utils/geoUtils');

// Create Complaint (Citizen only)
router.post('/', verifyJWT, checkRole(['user']), async (req, res) => {
  try {
    const { title, description, image, location } = req.body;

    // Duplicate detection (30m radius)
    const existingComplaints = await Complaint.find({ 
      status: { $ne: 'RESOLVED' },
      duplicateOf: { $exists: false }
    });
    console.log(`Checking duplicates among ${existingComplaints.length} non-resolved complaints...`);

    let duplicate = null;
    for (const comp of existingComplaints) {
      const distance = calculateDistance(
        comp.location.latitude,
        comp.location.longitude,
        location.latitude,
        location.longitude
      );
      console.log(`- Dist to "${comp.title}": ${distance.toFixed(2)}m`);
      if (distance <= 30) {
        duplicate = comp;
        console.log(`  MATCH FOUND!`);
        break;
      }
    }

    if (duplicate) {
      // If user confirms (via separate flag or just returning error for now)
      // For this requirement, we'll return a 409 Conflict with the original image
      return res.status(409).json({ 
        message: 'A similar type of complaint is already registered from near your location',
        existingComplaint: {
          title: duplicate.title,
          image: duplicate.image,
          status: duplicate.status,
          id: duplicate._id
        }
      });
    }

    const complaint = new Complaint({
      title,
      description,
      image,
      location,
      createdBy: req.user.userId,
      status: 'PENDING'
    });
    await complaint.save();
    res.status(201).json(complaint);
  } catch (error) {
    res.status(500).json({ message: 'Error creating complaint', error });
  }
});

// Confirm Duplicate (Link to existing)
router.post('/:id/confirm-duplicate', verifyJWT, async (req, res) => {
    try {
        const original = await Complaint.findById(req.params.id);
        if (!original) return res.status(404).json({ message: 'Original complaint not found' });

        // Increment count
        original.reportCount += 1;
        await original.save();

        // Create a record for this user too, but linked
        const linked = new Complaint({
            title: original.title + " (Duplicate)",
            description: "User reported same issue",
            image: original.image, // Use original or user's? The user said "show pictures of similar", I'll keep it simple
            location: original.location,
            createdBy: req.user.userId,
            status: original.status,
            duplicateOf: original._id
        });
        await linked.save();

        res.json({ message: 'Linked to existing complaint', original });
    } catch (error) {
        res.status(500).json({ message: 'Error linking duplicate' });
    }
});

// Get Complaints (Role-based filtering)
router.get('/', verifyJWT, async (req, res) => {
  try {
    let query = {};
    if (req.user.role === 'user') {
      // Citizen sees their own (including those linked as duplicates)
      query.createdBy = req.user.userId;
    } else if (req.user.role === 'admin') {
      // Admin sees only "Original" complaints (not the linked duplicates)
      // because they want to see "10 citizens facing..." as a consolidation
      query.duplicateOf = { $exists: false };
    } else if (req.user.role === 'engineer') {
      query.assignedEngineerId = req.user.userId;
    }
    
    const complaints = await Complaint.find(query)
      .populate('createdBy', 'name')
      .populate('assignedEngineerId', 'name')
      .sort({ createdAt: -1 });

    res.json(complaints);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching complaints' });
  }
});

// Verify (Admin only)
router.put('/:id/verify', verifyJWT, checkRole(['admin']), async (req, res) => {
  try {
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) return res.status(404).json({ message: 'Not found' });
    if (complaint.status !== 'PENDING') return res.status(400).json({ message: 'Invalid state transition' });

    complaint.status = 'VERIFIED';
    complaint.verifiedAt = new Date();
    await complaint.save();
    res.json(complaint);
  } catch (error) {
    res.status(500).json({ message: 'Error verifying complaint' });
  }
});

// Assign (Admin only)
router.put('/:id/assign', verifyJWT, checkRole(['admin']), async (req, res) => {
  try {
    const { engineerId } = req.body;
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) return res.status(404).json({ message: 'Not found' });
    if (complaint.status !== 'VERIFIED') return res.status(400).json({ message: 'Must be verified first' });

    complaint.status = 'ASSIGNED';
    complaint.assignedEngineerId = engineerId;
    complaint.assignedAt = new Date();
    await complaint.save();
    res.json(complaint);
  } catch (error) {
    res.status(500).json({ message: 'Error assigning complaint' });
  }
});

// Resolve (Engineer only)
router.put('/:id/resolve', verifyJWT, checkRole(['engineer']), async (req, res) => {
  try {
    const { resolutionImage, currentLocation } = req.body;
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) return res.status(404).json({ message: 'Not found' });
    if (complaint.status !== 'ASSIGNED') return res.status(400).json({ message: 'Must be assigned first' });

    // Distance check
    const distance = calculateDistance(
      complaint.location.latitude,
      complaint.location.longitude,
      currentLocation.latitude,
      currentLocation.longitude
    );

    console.log(`Resolution Distance Check for "${complaint.title}":`);
    console.log(`- Complaint Location: ${complaint.location.latitude}, ${complaint.location.longitude}`);
    console.log(`- Engineer Location: ${currentLocation.latitude}, ${currentLocation.longitude}`);
    console.log(`- Calculated Distance: ${distance.toFixed(2)}m (Threshold: 30m)`);

    if (distance > 30) {
      return res.status(400).json({ 
        message: `Too far! You are ${Math.round(distance)}m away. Must be within 30m.`,
        calcDistance: distance
      });
    }

    complaint.status = 'RESOLVED';
    complaint.resolutionImage = resolutionImage;
    complaint.resolvedAt = new Date();
    await complaint.save();
    
    console.log(`- SUCCESSFULLY RESOLVED: "${complaint.title}"`);
    res.json(complaint);
  } catch (error) {
    console.log(`- RESOLUTION ERROR for "${req.params.id}":`, error);
    res.status(500).json({ message: 'Error resolving complaint', error: error.message });
  }
});

// Analytics (Admin only)
router.get('/analytics', verifyJWT, checkRole(['admin']), async (req, res) => {
  try {
    const total = await Complaint.countDocuments();
    const pending = await Complaint.countDocuments({ status: 'PENDING' });
    const resolved = await Complaint.countDocuments({ status: 'RESOLVED' });
    
    // Average resolution time
    const resolvedComplaints = await Complaint.find({ status: 'RESOLVED' });
    let totalTime = 0;
    resolvedComplaints.forEach(c => {
      totalTime += (c.resolvedAt - c.createdAt);
    });
    const avgTime = resolvedComplaints.length > 0 ? (totalTime / resolvedComplaints.length / (1000 * 60 * 60 * 24)).toFixed(2) : 0;

    res.json({ total, pending, resolved, avgTimeDays: avgTime });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching analytics' });
  }
});

module.exports = router;
