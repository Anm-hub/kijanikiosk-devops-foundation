# Week 5 Reflection

## 1. A difficult decision

One design decision was how to create a unique package version without changing the application's source version for every pipeline run. I chose to combine the version from `package.json` with the short Git commit identifier, for example `1.1.0-d8acf23`. The publish step copies the build output and package metadata into a temporary directory before setting the publication version. This keeps the release identifier traceable to the source revision without permanently rewriting the application's tracked `package.json`.

## 2. Translating board language into technical language

Board-level sentence: “A failed check marks the pipeline as unsuccessful and prevents dependent later stages from running.”

Technical translation: Jenkins evaluates the result of each stage. When a required stage fails, the sequential downstream stages are skipped. In the Verify stage, Test and Security Audit are configured as parallel branches; the pipeline must satisfy the stage's success conditions before it proceeds to Archive and Publish. The controlled fault runs demonstrated this behaviour.

The board version focuses on the business outcome—an unsuccessful change is not released through this pipeline—while the technical version explains how Jenkins stages, parallel branches and build results implement that outcome.

## 3. Scaling from four developers to forty

The first pressure point would likely be shared CI capacity and ownership: more simultaneous changes can create queueing, while a single Jenkins controller and a shared job configuration can become a bottleneck. The first improvement I would make is to formalise the pipeline as a reviewed, reusable shared library or centrally maintained pipeline template, paired with branch protection and clear ownership. This would reduce duplicated configuration and inconsistent changes across repositories. I would then measure queue time and build duration before increasing agent capacity, rather than scaling infrastructure without evidence.
