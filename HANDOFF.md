# devday-ttt-emea-2026 handoff

## Objective and status

Track all actionable feedback from the EMEA train-the-trainer session as GitHub issues, place tutorial issues in `rhpds/ocp-dev-days-rdshw-showroom` and platform/GitOps issues in `rhpds/ocp-dev-days-rdshw-gitops`, group them under a parent issue named `devday-ttt-emea-2026`, and implement fixes in subsequent work. This file is shared across the two repositories on branch `feat/devday-ttt-emea-2026-handoff`.

Status on 2026-10-10: planning and duplicate audit in progress. No fixes, new issues, or parent issue have been created. Do not mark work complete based on this handoff.

## Source and decisions

- The session feedback was reviewed with `gws docs documents get`. It has one tab, three open comment threads, one resolved thread, and no suggestions. Embedded screenshots need review.
- The resolved Dev Spaces thread concluded that a missing **Open** action was a navigation mistake. Do not file that as a separate bug. The independent report that Module 1 opens `camel-lab` remains actionable.
- GitHub supports parent issues with sub-issues across repositories. Create one parent issue in the showroom repository, then attach all distinct work items as sub-issues. Use existing attendee issues where they already cover the report. See [GitHub's sub-issue documentation](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues).
- GitHub CLI access is working with approval. Draft pull requests for this handoff are [showroom #32](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/pull/32) and [GitOps #48](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/pull/48), pushed from the `blues-man` forks.

## Duplicate audit already confirmed

| Existing issue | Coverage | Action |
| --- | --- | --- |
| [showroom #28](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/28) | GitLab login instructions: unclear what happens without a login prompt. | Reuse and link to parent; no duplicate. |
| [showroom #30](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/30) | RHDH system exposes broken relations to other users' components. | Reuse. It is a platform issue filed in showroom; consider transferring to GitOps while preserving its history, or retain it as a documented exception. Do not create a duplicate. |
| [showroom #24](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/24), [#25](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/25), [#29](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/29), [#31](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/31) | Other same-day Module 1 reports. | Read bodies and comments with `gh` before creating related tutorial issues. |
| [gitops #34](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/34), [#37](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/37) | Dev Spaces startup and Zoo Code on Firefox. | Check bodies for overlap before filing Zoo Code source-access or workspace issues. |

## Work items to track

| Area | Feedback and proposed outcome | Repo | Issue |
| --- | --- | --- | --- |
| Module 1 | Clarify GitLab no-prompt path. | Showroom | [#28](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/28) |
| Module 1 | Match **Choose** button; make **Open in Catalog → component → View Source** explicit. | Showroom | Audit #24/#25, then link or create |
| Module 1 | Replace the fixed `total: 15` claims example if fresh seed data returns `8`; verify screenshot. | Showroom | Pending |
| Module 1 | Explain feature-branch workspace selection when Dev Spaces initially opens `camel-lab`. | Showroom | Pending |
| Module 1 | Make creation of `src/main/java/com/parasol/ClaimsStatsResource.java` reliable, possibly with an empty upstream starter file. | Showroom for guide; upstream Parasol source for starter file | Pending |
| Module 3 | Stop shared copy control appending a newline to Kaoto and chat values. `copypaste.adoc` currently calls `writeText(text + '\n')`. | Showroom | Pending |
| Module 3 | Add Restricted Mode workspace-trust recovery; align Module 1 note. | Showroom | Pending |
| Module 3 | Explain Service Interconnect/Skupper CLI versus resource YAML; retain visible resource model. | Showroom | Pending |
| Module 3 | Clarify Connectivity Link naming versus Service Interconnect. | Showroom | Pending |
| Modules 1/3/5 | Standardize IDE theme guidance and fix Module 5 light-theme contrast. | Showroom | Pending |
| Showroom | Explain or fix RHDH links opening outside showroom tabs and losing instructions context. | Showroom | Pending |
| RHDH | Remove broken cross-user catalog relations and make the attendee's API discoverable without broadening access. | GitOps, with upstream catalog source/template inspection | [showroom #30](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/30), transfer candidate |
| RHDH scaffold | Investigate degraded status while Maven PVC syncs until first pipeline; make status/next step clear. | GitOps, with upstream `rhdh-templates` inspection | Pending |
| Zoo Code | Reproduce inability to read workspace source; inspect trust, mounts, extension, model/tool configuration, logs. | GitOps | Audit #34/#37, then link or create |
| Module 2 baseline | Keep images and `pom.xml` current so pipeline/TPA findings match the guide; coordinate upstream Parasol source changes. | GitOps | Pending |

## Implementation sequence

1. Audit open and recently closed issues from both repositories, inspect bodies/comments, and fill the `Issue` column with verified links. Avoid duplicate issues.
2. Create the `devday-ttt-emea-2026` parent issue in showroom and attach distinct existing/new issues as sub-issues. If cross-repo sub-issues are unavailable, use a shared label plus parent checklist with full URLs.
3. Implement confirmed guide and clipboard fixes, then preview Antora and check copy behavior in terminal, Kaoto, and chat.
4. Reproduce catalog, scaffold/PVC, and Zoo Code issues with fresh non-admin tenants before changing RBAC or templates.
5. Coordinate upstream source and image/dependency baseline changes; refresh screenshots and run Modules 1, 3, and 5 end to end, including a second tenant for catalog isolation.

After each change, update this file with the issue/PR URL, branch, what changed, verification performed, and remaining work. Keep the counterpart `HANDOFF.md` in the other repository in sync.
