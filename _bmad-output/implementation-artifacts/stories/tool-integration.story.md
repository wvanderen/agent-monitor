---
story_id: tool-integration-2024-02
title: Add Notification Tools and Automated Remediation
status: in-progress
---

## Description
Add actionable notifications and automated remediation workflows to Agent Monitor. Currently, system only alerts via console - need Slack, email, and automated fix execution.

## Acceptance Criteria
- [x] Slack webhook integration sends alerts with severity routing
- [x] Email templates generate HTML/text incident reports
- [x] Automated remediation can restart unhealthy services
- [x] Incident response playbooks run predefined fix sequences
- [x] Notification service abstraction allows easy addition of new channels
- [x] E2E tests verify notification delivery and remediation execution

## Technical Context
- [x] Supervisor needs new child spec for remediation workers
- [x] Coordinator needs notification dispatcher
- [x] Email service requires SMTP configuration or API integration
- [x] Slack client needs webhook handling and rate limiting
- [x] Remediation runner needs process isolation (don't crash monitor on bad playbook)

## Implementation Notes
- [x] Start with Slack (highest impact, familiar stack)
- [x] Use Resend/SendGrid for email (better deliverability)
- [x] Playbook DSL should be YAML/JSON based (easy to read and write)
- [x] Remediation jobs should be supervised (fault tolerance!)
- [x] Add Monitor.Console.remediate(url, playbook_id) command

## Implementation Details
- Added Notifications.Dispatcher GenServer for managing multiple notification channels
- Implemented Slack webhook client with rate limiting and retry logic
- Created Email channel with HTML and text template rendering
- Built Remediation system with safety checks and service health detection
- Developed Playbooks system with YAML/JSON DSL and process isolation
- Integrated notification dispatcher with Monitor.Coordinator for automatic alerts
- Added E2E tests for notifications and remediation functionality
