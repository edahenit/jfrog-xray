# Release Notes — JFrog Xray 3.88.1 → 3.137

**Audience:** Xray users (security teams, developers, policy managers)
**Purpose:** a summary of the functional changes introduced by this upgrade, from a day-to-day usage perspective. Purely technical installation and operations topics are not covered here.
**Scope:** this document covers only the **Xray SCA** (Software Composition Analysis) features actually used in your environment. The modules you do not use are intentionally excluded:
- **JFrog Advanced Security (JAS)** — CVE contextual analysis, SAST, secrets detection, IaC security, exposures scanning.
- **JFrog Curation** — preventive blocking of open source dependencies.

**Sources:** official JFrog documentation (see the References section at the end).

---

## At a glance

This upgrade spans more than 40 intermediate versions. For you as a user, the most visible changes fall into four areas:

- **More accurate vulnerability detection** (base image detection, CVSS v4 scores).
- A **new SBOM service** (activation coming soon) that changes how software bills of materials are generated and used.
- A **new Xray home page** providing a unified view of your security posture.
- **Richer reports and exports**, plus many performance improvements.

---

## 1. Software Composition Analysis (SCA) and scanning

### Base Image Detection
Xray now distinguishes vulnerabilities that originate in a container's **base image** from those introduced by your **application layers**. In practice, you can tell more quickly whether an issue comes from the underlying image (and calls for an image update) or from your own content, which speeds up triage and remediation.

### CVSS v4 support
In addition to CVSS v3, Xray now displays **CVSS v4** scores where available. You get a finer, more current severity assessment to prioritize your actions.

### Malicious package and operational risk detection
The SCA capabilities for detecting **malicious packages** and assessing **operational risk** (outdated or poorly maintained packages, etc.) benefit from continuous updates to the JFrog vulnerability database.

### Broader scan coverage
The scope covered by SCA scanning has expanded across versions, notably including **builds** and **Release Bundles v2**, for consistent visibility across all your artifacts.

### Vulnerability database
The vulnerability database continues to grow, with improved data quality (descriptions, fixed versions, references). Synchronization now uses **DB Sync v3** (see the Performance section).

---

## 2. Policies, watches, and violations

- **Policy** and **watch** management is preserved and hardened: your security and license rules continue to apply normally after the upgrade.
- **Ignore rules** now accept *Ant*-style patterns (for example `**/test/**`), making it easier to exclude specific paths.
- Clearer, faster display and filtering of **violations**.

---

## 3. SBOM service (new — activation coming soon)

Xray introduces an **SBOM service** built on a data model optimized for CVE search, Software Bill of Materials generation, and impact analysis. **This feature will be activated in your environment soon.**

For you, this means:

- **Faster and more reliable SBOM generation**, in standard industry formats.
- Improved **impact analysis**: quickly identify which components and applications are affected by a given vulnerability.
- A solid foundation for meeting regulatory and contractual SBOM requirements.

> **Important:** this service is not enabled by default. **Its activation is planned soon** in your environment; it is performed by your administrator and involves a data migration. Once enabled, the enriched SBOM features become available in the interface and via the API. A communication will be sent to you at the time of activation.

---

## 4. Interface and user experience

### New Xray Overview page
A new home page provides a **unified view of your security posture**: a summary of violations, trends, and areas that need your attention. It serves as an entry point for navigating Xray efficiently.

### Miscellaneous interface improvements
- Clearer, faster display and filtering of **violations**.
- **Accessibility** improvements (alternative text, screen readers).
- Better presentation of scan results and vulnerability details.

---

## 5. Reports, exports, and API

- **SBOM generation** in standard formats, usable for your compliance obligations.
- Improvements to **violation reports** and their export.
- Enriched **APIs** around SBOM and violations, for your integrations and automations.

---

## 6. Performance and reliability

Many optimizations, transparent to you but noticeable in use:

- Faster **indexing** of artifacts and builds.
- Faster **violation** and search queries.
- Optimized **SBOM** generation.
- Move to **DB Sync v3** for synchronizing the vulnerability database, replacing the previous version.

---

## 7. Frequently asked questions

**Are my existing policies and watches preserved?**
Yes. Your policies, watches, and ignore rules are preserved by the upgrade. It is nonetheless recommended to revalidate them afterward.

**Will I lose my scan history?**
No. Scan and vulnerability data is stored in the database and preserved during the upgrade.

**Do I need to do anything to benefit from CVSS v4 or base image detection?**
No, these improvements are available automatically after the upgrade.

**How do I enable enriched SBOM generation?**
Enabling the SBOM service is done by your administrator and is planned soon. Once active, the corresponding features appear automatically in the interface and API, and a communication will be sent to you.

---

## References

- Xray Release Notes — https://docs.jfrog.com/releases/docs/xray
- Xray Deprecations — https://docs.jfrog.com/releases/docs/xray-deprecations
- How to Enable and Monitor SBOM Migration — https://docs.jfrog.com/security/docs/how-to-enable-and-monitor-sbom-migration-in-xray
- Xray SCA (Software Composition Analysis) — https://jfrog.com/xray/

---

*Summary document intended for users. For installation, sizing, and operations procedures, refer to the dedicated upgrade plan and the JFrog administration documentation. Actually available features depend on your license and on the configuration chosen by your administrator.*
