---
name: azure-devops
description: Automatically assists with Azure DevOps work item management. Activates: When working with Azure DevOps work items (Features, User Stories, Tasks, Bugs)
---

> [!CAUTION]
> **Auto-generated file** - Do not edit directly.
> Source: `plugins/azure/skills/azure-devops/SKILL.md`
> Regenerate with: `npm run build`


# Azure DevOps Work Items Skill

This skill automatically activates when:
- Creating or updating Azure DevOps work items (Features, User Stories, Tasks, Bugs)
- Querying work item boards or backlogs
- Managing sprints and iterations

## Capabilities

- Create Features with WSJF calculations and proper field organization
- Create User Stories with "As a [role], I want [goal], so that [benefit]" format
- Query and report on work items across iterations
- Manage work item relationships and hierarchies

## Formatting Rules

When posting comments via `wit_add_work_item_comment` or `wit_update_work_item_comment`, always use `format: markdown`.

Allowed formatting in comment text:
- **Bold** (`**texto**`) and *italic* (`*texto*`) for emphasis
- Links: `[texto](url)`
- Plain line breaks (blank line between paragraphs)

Do NOT use:
- Backtick code formatting (`` `código` ``) — write the name inline as plain text
- HTML tags (`<br>`, `<b>`, `<code>`, etc.)
- HTML entities (`&lt;`, `&amp;`, etc.)

## Available MCP Tools

When this skill activates, use Azure DevOps MCP server tools:
- `mcp__AzureDevOps__wit_create_work_item` - Create work items
- `mcp__AzureDevOps__wit_update_work_item` - Update work items
- `mcp__AzureDevOps__wit_get_work_item` - Get work item details
- `mcp__AzureDevOps__wit_get_work_items_batch_by_ids` - Get multiple work items
- `mcp__AzureDevOps__work_list_iterations` - List iterations/sprints
- `mcp__AzureDevOps__work_list_team_iterations` - List team iterations

## User Identification

Resolve the current user's email by running `az account show --query user.name -o tsv`, then use `mcp__AzureDevOps__core_get_identity_ids` with that email to get the user's identity for assignments.
