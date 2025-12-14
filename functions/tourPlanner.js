// Tour Planner was removed from the project per user request.
// Keep a minimal exported handler that returns HTTP 410 (Gone) so any
// accidental calls receive a clear response rather than a 404 or crash.

module.exports = async function tourPlannerHandler(req, res) {
  res.status(410).json({
    error: 'Tour Planner feature removed',
    message: 'This endpoint has been intentionally removed from the project.',
  });
};
