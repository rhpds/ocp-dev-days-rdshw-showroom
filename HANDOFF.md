# devday-ttt-emea-2026 handoff

## Objective and status

Track all actionable feedback from the EMEA train-the-trainer session as GitHub issues, place tutorial issues in `rhpds/ocp-dev-days-rdshw-showroom` and platform/GitOps issues in `rhpds/ocp-dev-days-rdshw-gitops`, group them under a parent issue named `devday-ttt-emea-2026`, and implement fixes in subsequent work. This file is shared across the two repositories on branch `feat/devday-ttt-emea-2026-handoff`.

Status on 2026-10-10: [parent tracker #33](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/33) and distinct feedback issues are open. Implementation is in progress. Do not mark an issue complete without recording its verification.

## Source and decisions

- The session feedback was reviewed with `gws docs documents get`. It has one tab, three open comment threads, one resolved thread, and no suggestions. Embedded screenshots need review.
- The resolved Dev Spaces thread concluded that a missing **Open** action was a navigation mistake. Do not file that as a separate bug. The independent report that Module 1 opens `camel-lab` remains actionable.
- Native sub-issue attachment to the showroom parent was denied for the current GitHub account. [Parent #33](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/33) therefore has a checklist of full issue URLs. Use existing attendee issues where they already cover the report.
- GitHub CLI access is working with approval. Draft pull requests for this handoff are [showroom #32](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/pull/32) and [GitOps #48](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/pull/48), pushed from the `blues-man` forks.

## Duplicate audit already confirmed

| Existing issue | Coverage | Action |
| --- | --- | --- |
| [showroom #28](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/28) | GitLab login instructions: unclear what happens without a login prompt. | Reuse and link to parent; no duplicate. |
| [showroom #30](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/30) | RHDH system exposes broken relations to other users' components. | Reuse. It is a platform issue filed in showroom; consider transferring to GitOps while preserving its history, or retain it as a documented exception. Do not create a duplicate. |
| [showroom #24](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/24), [#25](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/25) | Same catalog relation symptom as #30. | Track one investigation under #30. |
| [showroom #29](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/29), [#31](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/31) | Distinct Module 1 guide and task reports. | Reuse and include in the parent checklist. |
| [gitops #34](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/34), [#37](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/37) | Dev Spaces startup and Zoo Code on Firefox. | Related but distinct from the source-access investigation #50. |

## Work items to track

| Area | Feedback and proposed outcome | Repo | Issue |
| --- | --- | --- | --- |
| Module 1 | Clarify GitLab no-prompt path. | Showroom | [#28](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/28) |
| Module 1 | Match **Choose** button; make **Open in Catalog → component → View Source** explicit. | Showroom | [#34](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/34) |
| Module 1 | Replace the fixed `total: 15` claims example if fresh seed data returns `8`; verify screenshot. | Showroom | [#35](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/35) |
| Module 1 | Explain feature-branch workspace selection when Dev Spaces initially opens `camel-lab`. | Showroom | [#36](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/36) |
| Module 1 | Make creation of `src/main/java/com/parasol/ClaimsStatsResource.java` reliable, possibly with an empty upstream starter file. | Showroom for guide; upstream Parasol source for starter file | [#37](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/37) |
| Module 3 | Stop shared copy control appending a newline to Kaoto and chat values. `copypaste.adoc` currently calls `writeText(text + '\n')`. | Showroom | [#38](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/38) |
| Module 3 | Add Restricted Mode workspace-trust recovery; align Module 1 note. | Showroom | [#39](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/39) |
| Module 3 | Explain Service Interconnect/Skupper CLI versus resource YAML; retain visible resource model. | Showroom | [#40](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/40) |
| Module 3 | Clarify Connectivity Link naming versus Service Interconnect. | Showroom | [#41](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/41) |
| Modules 1/3/5 | Standardize IDE theme guidance and fix Module 5 light-theme contrast. | Showroom | [#42](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/42) |
| Showroom | Explain or fix RHDH links opening outside showroom tabs and losing instructions context. | Showroom | [#43](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/43) |
| RHDH | Remove broken cross-user catalog relations and make the attendee's API discoverable without broadening access. | GitOps, with upstream catalog source/template inspection | [showroom #30](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/30), transfer candidate |
| RHDH scaffold | Investigate degraded status while Maven PVC syncs until first pipeline; make status/next step clear. | GitOps, with upstream `rhdh-templates` inspection | [#49](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/49) |
| Zoo Code | Reproduce inability to read workspace source; inspect trust, mounts, extension, model/tool configuration, logs. | GitOps | [#50](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/50) |
| Module 2 baseline | Keep images and `pom.xml` current so pipeline/TPA findings match the guide; coordinate upstream Parasol source changes. | GitOps | [#51](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/51) |

## Investigation notes

- [Showroom #30](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/30): The upstream `openshift-dev-days/parasol-insurance/catalog-info.yaml.template` gives the Component and API per-user names using `{{user_guid}}`, but both `spec.system` references point to shared `parasol-insurance`. The GitOps bootstrap substitutes `user_guid`; its Developer Hub RBAC exposes shared System/API entities while Components remain owner-only. This plausibly explains cross-user broken relations. The likely source fix is a per-user System entity and per-user `spec.system` references in the upstream template, followed by a fresh two-tenant catalog check. Do not broaden RBAC based on this finding alone. No live reproduction or code change was performed in the two repositories.
- [Showroom #28](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/28): The Module 1 GitLab step now distinguishes a login prompt from an existing signed-in session. The issue agent checked the guide diff and `git diff --check`; a fresh browser walkthrough remains pending.
- [Showroom #34](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/34): The template step now says **Choose**. The next steps identify the development component, its **Overview** tab, and the **About → View Source** action. The issue agent checked the guide diff and `git diff --check`; a current Developer Hub walkthrough remains pending.
- [Showroom #35](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/35): The claims statistics example now shows eight claims with the category/status values seen in the existing screenshot and says seed counts can vary. The issue agent checked the screenshot and `git diff --check`; a fresh tenant endpoint check remains pending.
- [Showroom #36](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/36): Module 1 now explains how to return from the `camel-lab` workspace to the participant's Parasol development component and select the feature-branch workspace. The issue agent checked the guide diff; a live Dev Spaces navigation check remains pending.
- [Showroom #37](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/37): Module 1 now places `ClaimsStatsResource.java` beside `ClaimsResource.java`, tells attendees to confirm the editor breadcrumb and full relative path before pasting, and gives a recovery step if it lands elsewhere. The issue agent checked the guide diff; a fresh IDE walkthrough remains pending.
- [Showroom #39](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/39): Modules 1 and 3 now give a Restricted Mode recovery path through the status bar or banner to Workspace Trust, followed by extension prompts. The issue agent checked the IDE wording against VS Code documentation and `git diff --check`; a current Dev Spaces screenshot and live check remain pending.
- [Showroom #41](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/41): Module 3 now identifies Service Interconnect as the application connection to a database in another namespace on the same cluster, and Connectivity Link as Gateway API policies that govern the LLM endpoint. The issue agent checked four guide pages and `git diff --check`; a rendered diagram review remains pending.
- [Showroom #38](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/38): Changed the shared copy control to copy `textarea.value` exactly, without appending a newline. Module 3 now tells attendees to press Enter after pasting terminal commands. The issue agent verified exact copied output for a command, Kaoto field, and chat prompt, and `git diff --check` passed. Full browser/Antora preview remains to be done before closing the issue.
- [GitOps #49](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/49): The feature-branch scaffold lives in external `openshift-dev-days/rhdh-templates/templates/parasol-dev-environment`. Its template registers the catalog component after creating the Argo Application, while the Deployment references an image tagged `latest` that the first push PipelineRun builds. An unavailable image could explain the initial Degraded status, but the exact health message has not been reproduced. The GitOps repository's `tenant/parasol-insurance-tenant/templates/job-initial-build.yaml` builds baseline manifests through a different path. In a designated fresh tenant, capture timestamped Developer Hub and Argo health, Deployment/Pod events and image waiting reason, Maven PVC status, and PipelineRuns through the first successful run. Then fix the observed cause or clarify an expected transitional status in the upstream template/guide. The current cluster context is unrelated to this lab, so no live test was performed.
- [GitOps #50](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/50): No deterministic defect was found in `cluster/devspaces/devspaces-instance/templates/zoo-code-config.yaml`; it already sets `alwaysAllowReadOnly` and `alwaysAllowReadOnlyOutsideWorkspace` to `true`. The extension is installed through `cluster/openvsx/files/extension-list.json`; the Module 1 workspace definition is in an external devfiles repository. Existing Module 1 instructions include a manual fallback. Reproduce in Chrome with a fresh workspace: record extension version, presence of source under `/projects/workshop`, trust state, exact prompt and file-read tool result, extension-host logs, and mounted settings. GitOps #34 (service worker) and #37 (Firefox pane) describe different symptoms. No config change has been made without reproduction.
- [GitOps #51](https://github.com/rhpds/ocp-dev-days-rdshw-gitops/issues/51): Added `docs/module-2-baseline.md` with the upstream source and image inventory, fresh-tenant pipeline/TPA verification steps, finding disposition, and release review cadence. The recorded inputs are Quarkus BOM `3.17.5`, application runtime image `ubi9/openjdk-21-runtime:1.20`, and Maven/Sonar task image `ubi9/openjdk-21:1.20` at the documented upstream commits. These are an inventory, not a validated vulnerability baseline; a fresh pipeline and TPA report are still required before closing #51. No unverified version bump was made.

## Implementation sequence

1. Use [parent #33](https://github.com/rhpds/ocp-dev-days-rdshw-showroom/issues/33) and its checklist to track the audited issues. Keep links and completion status current.
2. Implement each distinct issue and record the change, verification, and any blocker in this handoff.
3. Implement confirmed guide and clipboard fixes, then preview Antora and check copy behavior in terminal, Kaoto, and chat.
4. Reproduce catalog, scaffold/PVC, and Zoo Code issues with fresh non-admin tenants before changing RBAC or templates.
5. Coordinate upstream source and image/dependency baseline changes; refresh screenshots and run Modules 1, 3, and 5 end to end, including a second tenant for catalog isolation.

After each change, update this file with the issue/PR URL, branch, what changed, verification performed, and remaining work. Keep the counterpart `HANDOFF.md` in the other repository in sync.
