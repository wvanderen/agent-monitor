---
story_id: tool-integration-2024-02
title: Add Notification Tools and Automated Remediation
status: in-progress
---

## Description
Add actionable notifications and automated remediation workflows to Agent Monitor. Currently, system only alerts via console - need Slack, email, and automated fix execution.

## Acceptance Criteria
- [ ] Slack webhook integration sends alerts with severity routing
- [ ] Email templates generate HTML/text incident reports
- [ ] Automated remediation can restart unhealthy services
- [ ] Incident response playbooks run predefined fix sequences
- [ ] Notification service abstraction allows easy addition of new channels
- [ ] E2E tests verify notification delivery and remediation execution

## Technical Context
- [ ] Supervisor needs new child spec for remediation workers
- [ ] Coordinator needs notification dispatcher
- [ ] Email service requires SMTP configuration or API integration
- [ ] Slack client needs webhook handling and rate limiting
- [ ] Remediation runner needs process isolation (don't crash monitor on bad playbook)

## Implementation Notes
- [ ] Start with Slack (highest impact, familiar stack)
- [ ] Use Resend/SendGrid for email (better deliverability)
- [ ] Playbook DSL should be YAML/JSON based (easy to read and write)
- [ ] Remediation jobs should be supervised (fault tolerance!)
- [ ] Add Monitor.Console.remediate(url, playbook_id) command
