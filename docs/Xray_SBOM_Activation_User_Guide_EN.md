# SBOM is coming to Xray — user guide

*What the SBOM activation means for you, and how to use it*

---

## Good news: SBOM will be enabled soon

Xray's **SBOM** feature will be enabled in our environment soon. This guide explains, in plain terms, what that means and how to use it day to day.

> **There's nothing for you to enable yourself.** Activation is handled by the administration team. You'll be notified as soon as it's available. This guide is here so you're ready on day one.

---

## First, what is an SBOM?

**SBOM** stands for *Software Bill of Materials*. It's the complete list of "ingredients" that make up an application:

- its components and libraries,
- the exact version of each one,
- the associated licenses,
- known vulnerabilities,
- and even the **dependencies of your dependencies** (transitive dependencies).

Think of a food product's ingredient label, but for your code.

---

## What you'll be able to do once SBOM is enabled

### 1. See the full composition of an artifact
On any scanned artifact, you'll see the list of its components, with their versions, licenses, and vulnerabilities — including both direct **and** transitive dependencies.

### 2. Generate and export an SBOM
In a few clicks, you'll be able to produce an artifact's bill of materials in a **standard format**, reusable everywhere (customers, audits, CI pipelines):

| Format | When to use it |
|---|---|
| **CycloneDX** | Security-oriented — includes exploitability information (VEX) |
| **SPDX** | Compliance- and license-management-oriented |

### 3. React quickly when a vulnerability hits
When a new vulnerability is announced, you'll be able to find, **within seconds**, all the artifacts and applications that contain the affected component. No more hours of manual investigation.

---

## How to generate an SBOM — step by step

### From the Xray interface

1. Open the scanned artifact you're interested in.
2. Display its components and dependencies.
3. Choose the **export scan results** option.
4. Select the **SBOM format** you want (CycloneDX or SPDX).
5. Generate and download the file.

The resulting file contains the complete bill of materials, ready to share or archive.

### From the API (for automated use)

If you automate your pipelines, you'll be able to generate an SBOM in a single request:

```bash
curl 'https://<url>/xray/api/v1/component/exportDetails' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <your_token>' \
  -d '{
    "component_name": "<name>:<version>",
    "package_type": "build",
    "output_format": "json",
    "cyclonedx": true,
    "cyclonedx_format": "json",
    "sha_256": "<checksum>"
  }' -o sbom.zip
```

Perfect for automatically producing a build's SBOM on every release.

---

## Worth knowing

- **Your settings don't change.** SBOM is added to Xray; it doesn't affect your policies, your watches, or the way you work.
- **Transitive dependencies are included** in exported SBOMs — an increasingly common regulatory requirement.
- **Scope:** this guide covers open source dependency analysis (SCA). The interactive dependency tree view belongs to a module (Advanced Security) that isn't enabled here, so it isn't available. The enriched dependency export, however, is.
- **Standard formats:** the SBOMs produced (CycloneDX, SPDX) are recognized across the industry and reusable by your customers and tools.

---

## Frequently asked questions

**Do I need to enable anything?**
No. Activation is handled by the administration team. You'll benefit from it automatically.

**When will it be available?**
Soon — you'll receive a dedicated communication.

**Will it slow down my scans?**
No. The SBOM engine is optimized; performance is actually improved.

**Can I automate SBOM generation in CI?**
Yes, via the API and the JFrog CLI.

**Another question?**
Contact the Xray administration team.

---

*Guide intended for Xray users. The features actually available depend on our license and chosen configuration. For the technical aspects of activation and operations, the administration team has dedicated documentation.*
