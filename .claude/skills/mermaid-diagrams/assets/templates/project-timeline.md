# Project Timeline Template

Ready-to-use Gantt charts for project planning and tracking.

## Basic Project Timeline

```mermaid
gantt
    accTitle: Basic Project Timeline
    accDescr: Project timeline from planning through development sprints to testing and production launch.
    title Project Timeline - [TODO: Project Name]
    dateFormat YYYY-MM-DD
    excludes weekends

    %% TODO: Update dates and tasks for your project

    section Planning
    Requirements gathering    :done, req, 2024-01-08, 10d
    Technical design         :done, design, after req, 5d
    Sprint planning          :done, plan, after design, 2d

    section Development Sprint 1
    User authentication      :active, auth, after plan, 7d
    Database setup           :db, after plan, 5d
    API scaffolding          :api, after db, 5d

    section Development Sprint 2
    Core features            :core, after auth, 14d
    Integration testing      :int, after core, 5d

    section Testing & Launch
    QA testing               :qa, after int, 7d
    Bug fixes                :crit, fix, after qa, 5d
    Staging deployment       :stage, after fix, 2d
    Production launch        :milestone, launch, after stage, 0d
```

## Software Release Plan

```mermaid
gantt
    accTitle: Software Release Plan v2.0
    accDescr: Four-phase release plan covering foundation, feature development, polish, and release with beta testing.
    title Release v2.0 Plan
    dateFormat YYYY-MM-DD
    excludes weekends

    section Phase 1: Foundation
    Architecture review      :done, arch, 2024-01-15, 5d
    Breaking changes         :done, break, after arch, 10d
    Migration scripts        :active, migrate, after break, 5d

    section Phase 2: Features
    Feature A - Backend      :feat-a-be, after migrate, 10d
    Feature A - Frontend     :feat-a-fe, after feat-a-be, 7d
    Feature B - Backend      :feat-b-be, after migrate, 8d
    Feature B - Frontend     :feat-b-fe, after feat-b-be, 7d
    Feature C                :feat-c, after feat-a-fe, 10d

    section Phase 3: Polish
    Performance optimization :perf, after feat-c, 7d
    Security audit           :crit, security, after perf, 5d
    Documentation            :docs, after feat-b-fe, 10d

    section Phase 4: Release
    Beta release             :milestone, beta, after security, 0d
    Beta testing             :beta-test, after beta, 14d
    Bug fixes                :crit, bugs, after beta-test, 7d
    RC1                      :milestone, rc1, after bugs, 0d
    Final testing            :final, after rc1, 5d
    GA Release               :milestone, ga, after final, 0d
```

## Sprint Planning

```mermaid
gantt
    accTitle: Sprint 15 Planning
    accDescr: Two-week sprint with task assignments, tech debt items, testing, and sprint review milestone.
    title Sprint 15 (Jan 15 - Jan 29)
    dateFormat YYYY-MM-DD
    axisFormat %a %d

    section Sprint Tasks
    TASK-201: Login redesign      :done, task201, 2024-01-15, 2d
    TASK-202: Dashboard widgets   :active, task202, after task201, 3d
    TASK-203: Export feature      :task203, after task202, 2d
    TASK-204: Notification system :task204, 2024-01-17, 4d

    section Tech Debt
    Refactor auth module        :crit, td1, 2024-01-15, 3d
    Update dependencies         :td2, after td1, 1d

    section Testing
    Write unit tests            :test1, after task202, 2d
    Integration tests           :test2, after task203, 2d

    section Milestones
    Sprint Review               :milestone, review, 2024-01-29, 0d
```

## Product Roadmap

```mermaid
gantt
    accTitle: Product Roadmap 2024
    accDescr: Quarterly product roadmap from MVP through public beta, mobile app, enterprise features, and AI integration.
    title Product Roadmap 2024
    dateFormat YYYY-MM-DD
    axisFormat %b

    section Q1
    MVP Development             :q1-mvp, 2024-01-01, 60d
    Private Beta                :q1-beta, after q1-mvp, 30d

    section Q2
    Public Beta                 :q2-beta, 2024-04-01, 45d
    Mobile App                  :q2-mobile, 2024-04-15, 60d
    Enterprise Features         :q2-ent, 2024-05-01, 45d

    section Q3
    API v2                      :q3-api, 2024-07-01, 45d
    Integrations                :q3-int, 2024-07-15, 60d
    Localization                :q3-i18n, 2024-08-01, 45d

    section Q4
    Analytics Dashboard         :q4-analytics, 2024-10-01, 45d
    AI Features                 :q4-ai, 2024-10-15, 60d
    Scale & Performance         :q4-scale, 2024-11-01, 45d
```

## Marketing Campaign

```mermaid
gantt
    accTitle: Product Launch Campaign
    accDescr: Marketing campaign timeline covering pre-launch research, launch week activities, and post-launch follow-up.
    title Product Launch Campaign
    dateFormat YYYY-MM-DD

    section Pre-Launch
    Market research         :research, 2024-02-01, 21d
    Brand messaging         :brand, after research, 14d
    Content creation        :content, after brand, 21d
    Website updates         :website, after brand, 14d

    section Launch Week
    Press release           :crit, press, 2024-04-01, 1d
    Social campaign start   :social, 2024-04-01, 14d
    Influencer outreach     :influencer, 2024-04-01, 7d
    Launch event            :milestone, event, 2024-04-03, 0d
    Email blast             :email, 2024-04-03, 1d

    section Post-Launch
    Monitor & respond       :monitor, after event, 14d
    Collect feedback        :feedback, after event, 21d
    Iterate messaging       :iterate, after feedback, 7d
    Case studies            :cases, after feedback, 14d
```

## Usage Instructions

1. Copy the relevant template
2. Update `title` with your project name
3. Adjust `dateFormat` if needed (common: `YYYY-MM-DD`)
4. Update section names and tasks
5. Set task dates and durations
6. Add dependencies with `after taskId`
7. Include `accTitle` and `accDescr` for accessibility
8. Test in [Mermaid Live Editor](https://mermaid.live/)

## Task Status

| Status | Syntax | Appearance |
|--------|--------|------------|
| Normal | `:taskId, date, duration` | Default bar |
| Done | `:done, taskId, date, duration` | Filled/completed |
| Active | `:active, taskId, date, duration` | Highlighted |
| Critical | `:crit, taskId, date, duration` | Red/urgent |
| Milestone | `:milestone, taskId, date, 0d` | Diamond marker |

## Date Formats

| Format | Example | Use |
|--------|---------|-----|
| `YYYY-MM-DD` | 2024-01-15 | Standard (default) |
| `axisFormat %b` | Jan, Feb | Monthly roadmaps |
| `axisFormat %a %d` | Mon 15 | Sprint-level detail |
| `axisFormat %d/%m` | 15/01 | European format |

## Tips

- Gantt charts do NOT support theme init blocks — styling is automatic
- Use `excludes weekends` to skip Sat/Sun
- Use `after taskId` for dependencies
- Use `axisFormat` to customize date display
- Keep task names short and descriptive
- Group related tasks in sections
