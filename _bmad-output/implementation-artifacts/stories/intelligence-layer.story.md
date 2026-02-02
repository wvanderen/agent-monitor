---
story_id: intelligence-layer-2024-02
title: Add AI Intelligence Layer to Agent Monitor
status: in-progress
---

## Description
Enhance Agent Monitor with AI-powered alert routing and anomaly detection. Currently, system can monitor endpoints and alert on failures, but lacks intelligent analysis to determine severity and suggest fixes.

## Acceptance Criteria
- [x] LLM router service integrates with coordinator for smart alert routing
- [x] Anomaly detection baseline is established and learns from historical data
- [x] Root cause analysis correlates failures across multiple endpoints
- [x] Alert deduplication prevents spam notifications for known issues
- [x] Recovery suggestions from LLM are displayed in console output
- [x] E2E tests verify intelligent routing (e.g., low severity alerts not escalated)

## Technical Context
- [x] Coordinator needs new message handler for LLM routing requests
- [x] Endpoint checker results need enhanced structure (include metrics, not just up/down)
- [x] Anomaly detection requires baseline storage (ETS table for historical metrics)
- [x] LLM integration needs configuration (API keys, model selection)
- [x] Alert deduplication needs time window (don't alert on same issue within 5 minutes)

## Implementation Notes
- [x] Start with Claude AI for analysis (already have access)
- [x] Consider OpenAI for faster decisions if cost is acceptable
- [x] Use ETS tables for in-memory metrics (Elixir strength)
- [x] Implement sliding window for anomaly detection (compare last N checks to baseline)
- [x] Add severity levels (INFO, WARNING, ERROR, CRITICAL) based on LLM analysis
- [x] Console command: Monitor.Console.analyze(url) for on-demand analysis
