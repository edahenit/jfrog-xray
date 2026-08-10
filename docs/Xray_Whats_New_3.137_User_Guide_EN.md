# What's new for you in the latest version of Xray

*A short, jargon-free guide to the changes*

Hello,

Our security platform, **JFrog Xray**, has just taken a big step forward. On paper, we're moving from version 3.88 to 3.137 — more than forty versions apart. But don't worry, there's nothing to relearn. Most of the changes work for you behind the scenes, and the few visible ones will actually make your life easier.

Here's what you'll notice, in just a few minutes of reading.

> **Worth knowing before we start.** This guide only covers what you use day to day: the analysis of open source dependencies (SCA). The modules our organization hasn't enabled — Advanced Security (JAS) and Curation — aren't covered here, so we don't clutter this with features that don't concern you.

---

## In a nutshell

If you only remember the essentials:

- Xray now spots vulnerabilities **more precisely**, so you waste less time on false alarms.
- A **new SBOM capability is coming soon**: an easy way to generate the "ingredient list" of your software.
- A **new home page** finally gives you a clear overview of where you stand.
- And overall, **everything is faster**.

Let's get into the details.

---

## 1. Smarter analysis, less noise

### Xray now knows where the problem comes from

Before, when a vulnerability showed up in a container image, you had to guess whether it came from the base image (the one you didn't write) or from your own code. Now, **Xray tells them apart on its own**. You can see immediately whether the fix means updating the base image or correcting something on your side. In short: less investigating, more fixing.

### More up-to-date severity scores

Xray now shows **CVSS v4** scores, the latest generation of vulnerability ratings, alongside the v3 scores you already know. That means you prioritize your fixes based on finer, more current information.

### Xray also hunts down booby-trapped packages

The detection of **malicious packages** and the assessment of **risky packages** (abandoned, no longer maintained…) keep improving automatically, thanks to continuous updates to JFrog's knowledge base. You don't have to do anything: it updates itself.

### Broader coverage

The scope of analysis has expanded: your **builds** and **Release Bundles** are now covered the same way as everything else. Consistent visibility, with no blind spots.

---

## 2. Your rules and alerts: nothing changes (and that's on purpose)

Good news for those who patiently configured their policies: **everything is preserved.** Your policies, watches, and ignore rules continue to work exactly as before.

Two small improvements along the way:

- **Ignore rules** now accept more flexible path formats (for example, excluding everything in a test folder in one go). No more listing paths one by one.
- The display of **violations** is clearer and faster to filter.

---

## 3. SBOM is coming soon — and it will matter

You'll be hearing more and more about **SBOM** (*Software Bill of Materials*). The idea is simple: it's the **complete ingredient list** of your applications — every component, every library, every version.

Xray introduces a fully redesigned SBOM engine, which brings:

- **Faster and more reliable** generation of that list, in formats recognized across the industry.
- Much better **impact analysis**: when a new vulnerability is announced, you identify within seconds which applications are affected.
- A calm way to meet the increasingly common **regulatory requirements** on this topic.

> **Keep in mind:** this feature **will be enabled soon** on our side. It requires a little preparation on the administration side, and you'll be notified as soon as it's available. Until then, there's nothing for you to do.

---

## 4. A more pleasant interface

### A real home page

Xray now greets you with an **overview** of your security posture: where your violations stand, what trends are emerging, where to focus first. No more searching: the essentials are right in front of you the moment you log in.

### Details that count

- Violation lists are clearer and filter faster.
- Accessibility has been improved (better screen-reader compatibility, alternative text).
- Scan results and vulnerability details are better presented.

---

## 5. Reports and automation

- You can generate **SBOMs** in standard formats, directly usable for your compliance obligations.
- **Violation reports** and their exports have been improved.
- The **APIs** have grown (SBOM, violations), for those who automate their integrations.

---

## 6. And above all: everything is faster

A lot of work has been done "under the hood." You won't see it directly, but you'll feel it:

- The **analysis** of your artifacts and builds is faster.
- **Searches** and violation displays respond instantly.
- **SBOM generation** is optimized.
- The mechanism for updating the vulnerability database has been modernized.

---

## Your questions, our answers

**Will I lose my settings?**
No. Your policies, watches, and exclusions are preserved. A quick check to revalidate after the update never hurts, but nothing is lost.

**And my scan history?**
Intact. Everything is preserved.

**Do I need to do anything to benefit from the new features (CVSS v4, base image detection…)?**
No, they're there automatically. Just enjoy them.

**When will I be able to use SBOM?**
Very soon. Activation is being prepared on the administration side, and you'll be informed as soon as it's ready.

**I have a question that isn't here…**
Feel free to contact the Xray administration team. That's what we're here for.

---

*This guide presents the new features from the perspective of your daily use. The features actually available depend on our license and chosen configuration. For technical topics (installation, operations), the administration team has dedicated documentation.*

*Thank you for reading, and enjoy the new version.*
