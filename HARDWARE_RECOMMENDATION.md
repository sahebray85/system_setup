# Laptop Hardware Recommendation

Prices are in INR, collected on 2026-09-20 from Indian e-commerce listings. The **Verified**
column says whether the price was read directly from the retailer page ("Page read") or came
from an aggregator / search summary because the retailer page blocked automated access.
Re-check on the day of purchase; laptop prices in India move weekly and Flipkart Big Billion
Days and Amazon Great Indian Festival run late September to October.

Software basis: `SOFTWARE_LIST_curated.md`.

## 1. Why these specs

| Software in the list | Hardware it drives |
|---|---|
| Docker Desktop, WSL2 Ubuntu, Virtual Machine Platform | RAM. WSL2 reserves up to half of system RAM by default and Docker images live in a WSL vhdx. This is the single biggest driver. |
| IntelliJ IDEA, VS Code, DBeaver, Postman | RAM and CPU cores (indexing, Gradle/Maven builds). |
| Three JDKs, Node 24, Python 3.11, Maven repo, Docker images, WSL disk | SSD space. A working developer tree easily reaches 150 to 250 GB. |
| Claude Code, Copilot CLI, Codex CLI | Nothing special. These call cloud APIs; no local GPU needed. |
| BitLocker, Zscaler, domain policies | Windows 11 **Pro**. |
| Teams, Zoom, WhatsApp, M365 | Webcam, mic, 8+ hours battery. |

Nothing in the list uses CUDA, Ollama or local model inference, so a dedicated GPU is not
required and would add roughly ₹1 lakh for no benefit.

### Minimum vs recommended

| Item | Minimum (occasional Docker) | Recommended (daily Docker + IntelliJ) |
|---|---|---|
| CPU | 8 cores, Ryzen 7 7730U / 7735HS or Core i7 12th gen+ | Ryzen AI 7 350 / Ryzen AI 9 HX 370 / Core Ultra 7-9 H |
| RAM | 16 GB, **must have a free SO-DIMM slot** | 32 GB |
| SSD | 512 GB NVMe | 1 TB NVMe |
| GPU | Integrated | Integrated |
| OS | Windows 11 Pro | Windows 11 Pro |
| Screen | 15.6 or 16 inch, 1080p or WUXGA, matte | same |
| Ports | 2× USB-C (one USB4/TB4), HDMI, USB-A | same |

## 2. Is 16 GB / 512 GB enough for employees?

**Yes, for occasional Docker use, under three conditions.**

1. **RAM must be upgradeable.** Buy only models with two SO-DIMM slots so 16 GB becomes
   32 GB later for about ₹3,000 per stick instead of a new laptop. Soldered LPDDR5X models
   are excluded from the employee list for this reason.
2. **Cap WSL2 memory** so Docker cannot take half the machine. Put this in
   `C:\Users\<name>\.wslconfig` and run `wsl --shutdown`:
   ```ini
   [wsl2]
   memory=6GB
   processors=4
   swap=2GB
   ```
   Quit Docker Desktop when not in use (it does not need to auto-start).
3. **Keep 512 GB usable** with `docker system prune -a` monthly and by not keeping more
   than one JDK per major version.

The current owner machine is 16 GB / 512 GB and struggles because Docker, WSL2 and IntelliJ
run together all day. That is a different workload from occasional use.

## 3. Section A: two employee laptops (15.6 or 16 inch, Windows 11 Pro, upgradeable RAM)

Add about **₹9,000 to ₹10,000 per unit** for a Windows 11 Pro upgrade key on any model that
ships with Home. Prices below show that adder where it applies.

### Band 2: ₹55,000 to ₹75,000 per unit (new)

| Model | Spec | Price | Windows | Upgradeable RAM | Source | Verified |
|---|---|---|---|---|---|---|
| **Lenovo ThinkBook 16 G7 ARP (21MW)** | Ryzen 7 7735HS (8C/16T), 16 GB DDR5, 512 GB SSD + 512 GB HDD, 16" WUXGA IPS 300 nits, 1.7 kg, 1 yr onsite | **₹72,675** (MRP ₹89,900; historic low ₹48,990) | **Pro** | Yes, 2× DDR5 SO-DIMM, max 64 GB | [Flipkart](https://www.flipkart.com/lenovo-thinkbook-16-amd-ryzen-7-octa-core-7th-gen-7735hs-16-gb-512-gb-hdd-512-ssd-windows-11-pro-thinbook-g7-arp-laptop/p/itmccd065cb21a4a) | Page read |
| Lenovo ThinkBook 16 (21MWA0AUIN) | Same chassis and CPU, 16 GB / 512 GB | ₹59,990 to ₹63,990 + ₹10k Pro ≈ ₹70k to ₹74k | Home | Yes, 2× SO-DIMM | [Amazon.in](https://www.amazon.in/Lenovo-ThinkBook-21MWA0AUIN-Fingerprint-Aluminium/dp/B0FD8TSZQC) | Aggregator (Amazon page returned 503) |
| Lenovo ThinkPad E16 Gen 2 AMD | Ryzen 7 7735HS or 7735U, 16 GB DDR5, 512 GB, 16" WUXGA | ₹65,000 to ₹67,990 (one listing ₹92,750) | Pro | Yes, 1 soldered + 1 SO-DIMM slot | [Amazon.in](https://www.amazon.in/ThinkPad-E16-Gen-Anti-Glare-Fingerprint/dp/B099F2BW49), [Smartprix](https://www.smartprix.com/laptops/lenovo-thinkpad-e16-gen-2-21m5s09e00-laptop-ppd14633fib2) | Aggregator |
| Dell 15 (DC15255) | Ryzen 7 7730U, 16 GB DDR4, 512 GB, 15.6" 120 Hz, 1.63 kg | ₹59,490 to ₹66,920 + ₹10k Pro | Home | Yes, 2× DDR4 SO-DIMM | [Flipkart](https://www.flipkart.com/dell-15-amd-ryzen-7-octa-core-7730u-16-gb-512-gb-ssd-windows-11-home-dc15255-thin-light-laptop/p/itm0225059e8adc4), [Amazon.in](https://www.amazon.in/Dell-15-Platinum-Graphics-Standard/dp/B0FDQ2R315) | Search result |

**Pick for band 2: ThinkBook 16 G7 ARP with Windows Pro at ₹72,675.** Business build,
aluminium lid, fingerprint reader, two RAM slots, onsite warranty, Pro included.
Two units ≈ **₹1,45,000**. If the Home variant is ₹15k cheaper on the day, buy it plus a
Pro key instead.

### Band 1: under ₹55,000 per unit (new)

| Model | Spec | Price | Windows | Upgradeable RAM | Source | Verified |
|---|---|---|---|---|---|---|
| Lenovo V15 G4 (AMD) | Ryzen 7 7730U, 16 GB DDR4, 512 GB, 15.6" FHD | ₹47,999 + ₹10k Pro ≈ ₹58k | Home | Yes, 1 soldered + 1 slot (check SKU) | [Smartprix](https://www.smartprix.com/laptops/price-below_55000?sort=spec_score&asc=0) | Aggregator |
| Acer Aspire Lite AL15-41 | Ryzen 7 7730U, 16 GB DDR4, 1 TB, 15.6" FHD | ₹48,990 + ₹10k Pro ≈ ₹59k | Home | Yes, 2× SO-DIMM | [Smartprix](https://www.smartprix.com/laptops/price-below_55000?sort=spec_score&asc=0) | Aggregator |
| HP 15 (Ryzen 7 7730U) | 16 GB DDR4, 512 GB, 15.6" FHD IPS | ₹50,990 + ₹10k Pro ≈ ₹61k | Home | Yes, 2× SO-DIMM | [Smartprix](https://www.smartprix.com/laptops/price-below_55000?sort=spec_score&asc=0) | Aggregator |

Once the Windows Pro key is added, every new band 1 laptop lands at ₹58k to ₹61k, which is
band 2 money for a consumer chassis. **New laptops do not really fit under ₹55k with Pro.**
Band 1 is best served by a certified refurbished business laptop (below), which already
includes Pro.

### Refurbished (1 year warranty, Grade A / Renewed Premium only)

Sellers checked against the rule "minimum 1 year warranty":

| Seller | Warranty (from their own policy page) | Meets rule | Notes |
|---|---|---|---|
| [Lenovo Certified Refurbished India](https://www.lenovo.com/in/en/certified-refurbished/) | 1 year Lenovo warranty, extendable to 3 | **Yes** | Original parts, ThinkPad/ThinkBook stock varies; price on request for 16" models |
| [Amazon.in Renewed](https://www.amazon.in/Core-i7-Laptop-Renewed-Computers-Accessories/s?rh=n:15730038031,p_n_condition-type:13736826031) | **Premium** condition: 1 year brand warranty, 365 day return. Excellent/Good: 6 months | **Yes, Premium only** | Filter to "Renewed Premium"; India stock is thin for 15.6" business models |
| [ReTechie](https://retechie.com/) | 2 years ReTechie warranty | **Yes** | Mostly Dell Precision and 14" ThinkPad T14 (i7 10th gen, 16 GB, 512 GB at ₹39,500); ask for 15.6" Latitude 5520 / 5530 |
| [Amrkart](https://amrkart.com/) | 12 months | Yes | Stock and pricing not verified |
| [NewJaisa](https://newjaisa.com/pages/warranty-policy-1) | **6 months** (policy page; blog text claiming 1 year is marketing) | No | Excluded. Most stock is 14" and 256 GB anyway |
| [Refurbo](https://refurbo.in/collections/buy-lenovo-thinkpad) | 6 months, "enquire for price" | No | Excluded |
| EazyPC, Budli | 6 months | No | Excluded |

Target spec for a refurb: **Dell Latitude 5520/5530, HP EliteBook 850 G8 / ProBook 450 G8/G9,
or Lenovo ThinkPad T15/L15 Gen 2**, Core i7 11th gen or newer, 16 GB, 512 GB NVMe, Windows
11 Pro, two SO-DIMM slots. Expect **₹38,000 to ₹52,000** per unit from the sellers marked
"Yes". Two units ≈ **₹0.8 to ₹1.05 lakh**. Insist on the invoice stating the warranty
length and battery health above 80 percent.

### Two-unit totals

| Option | Per unit | Two units | Windows Pro | Upgradeable |
|---|---|---|---|---|
| New ThinkBook 16 G7 ARP (band 2) | ₹72,675 | ≈ ₹1,45,000 | Included | Yes |
| New ThinkBook 16 Home + Pro key | ≈ ₹70,000 | ≈ ₹1,40,000 | Added | Yes |
| Certified refurb Latitude / EliteBook (band 1) | ₹38k to ₹52k | ≈ ₹0.8 to ₹1.05 lakh | Included | Yes |
| New consumer Ryzen 7 7730U + Pro key (band 1 stretched) | ≈ ₹58k to ₹61k | ≈ ₹1,20,000 | Added | Yes |

## 4. Section B: owner machine upgrade (32 GB / 1 TB, no GPU)

The owner runs Docker, WSL2 and IntelliJ all day, so 32 GB and 1 TB are the floor.

| Model | Spec | Price | Windows | Source | Verified |
|---|---|---|---|---|---|
| **ASUS Zenbook S16 UM5606WA** | Ryzen AI 9 HX 370 (12C), 32 GB LPDDR5X, 1 TB, 16" 3K OLED 120 Hz, 1.5 kg, 2× USB4, HDMI 2.1 | **₹1,49,990** (MRP ₹1,82,990; ₹1,45,990 with bank offer) + ₹10k Pro | Home | [Flipkart](https://www.flipkart.com/asus-zenbook-s-16-amd-ryzen-9-12-core-ai-hx-370-32-gb-1-tb-ssd-windows-11-home-um5606wa-rj3310ws-thin-light-laptop/p/itma6a0e0642f03b) | Page read |
| HP OmniBook Ultra 14 (fd0009AU) | Ryzen AI 9 HX 375, 32 GB LPDDR5X, 1 TB, 14" 2.2K touch | ₹1,38,990 + ₹10k Pro | Home | [Amazon.in](https://www.amazon.in/HP-OmniBook-Anti-Glare-Office24-fd0009AU/dp/B0F9P8HTHY) | Aggregator (503) |
| Lenovo ThinkPad T14s Gen 6 AMD | Ryzen AI 7 PRO 360, 32 GB, 256 GB (configure to 1 TB) | ₹1,37,268 base; 1 TB price on request | Pro | [Lenovo.in](https://www.lenovo.com/in/en/p/laptops/thinkpad/thinkpadt/lenovo-thinkpad-t14s-gen-6-14-inch-amd-laptop/len101t0109) | Aggregator (403) |
| Lenovo Legion 5 15 OLED (only if local AI models are planned) | Core Ultra 9 275HX, RTX 5070, 32 GB, 1 TB | ₹2,40,990 | Home | [Smartprix](https://www.smartprix.com/laptops/nvidia-geforce-rtx-5070-laptops-list) | Search result |

**Pick: Zenbook S16 at ₹1,49,990 plus a Pro key**, or the OmniBook Ultra 14 if a 14 inch
is preferred. Caveat: both have soldered RAM, so 32 GB is the permanent ceiling. That is
acceptable for this workload for four to five years.

## 5. Timing

The ThinkBook 16 G7 ARP has sold at ₹48,990 on Flipkart before. Big Billion Days and the
Great Indian Festival start within weeks of 2026-09-20. Waiting for the sale could save
₹15,000 to ₹20,000 per unit on the new options. Refurb prices move less.

## 6. Sources

- [Flipkart: ThinkBook 16 G7 ARP Win 11 Pro](https://www.flipkart.com/lenovo-thinkbook-16-amd-ryzen-7-octa-core-7th-gen-7735hs-16-gb-512-gb-hdd-512-ssd-windows-11-pro-thinbook-g7-arp-laptop/p/itmccd065cb21a4a)
- [Amazon.in: ThinkBook 16 21MWA0AUIN](https://www.amazon.in/Lenovo-ThinkBook-21MWA0AUIN-Fingerprint-Aluminium/dp/B0FD8TSZQC)
- [Price history: ThinkBook 16 G7 ARP](https://pricehistory.app/p/lenovo-thinkbook-16-amd-ryzen-7-octa-8ULVKvce)
- [Kingston: ThinkBook 16 G7 ARP memory (2 slots, DDR5 SO-DIMM, 64 GB max)](https://www.kingston.com/en/memory/search/model/109659/lenovo-thinkbook-16-g7-arp)
- [Lenovo PSREF: ThinkBook 16 G7 ARP](https://psref.lenovo.com/Product/ThinkBook_16_G7_ARP)
- [Amazon.in: ThinkPad E16 Gen 2 AMD](https://www.amazon.in/ThinkPad-E16-Gen-Anti-Glare-Fingerprint/dp/B099F2BW49)
- [Smartprix: ThinkPad E16 Gen 2 21M5S09E00](https://www.smartprix.com/laptops/lenovo-thinkpad-e16-gen-2-21m5s09e00-laptop-ppd14633fib2)
- [Flipkart: Dell 15 DC15255](https://www.flipkart.com/dell-15-amd-ryzen-7-octa-core-7730u-16-gb-512-gb-ssd-windows-11-home-dc15255-thin-light-laptop/p/itm0225059e8adc4)
- [Smartprix: laptops under ₹55,000 by spec](https://www.smartprix.com/laptops/price-below_55000?sort=spec_score&asc=0)
- [Lenovo Certified Refurbished India](https://www.lenovo.com/in/en/certified-refurbished/)
- [Amazon.in Renewed help page (warranty by condition)](https://www.amazon.in/gp/help/customer/display.html?nodeId=GRAS7M4E8YJCLWH7)
- [NewJaisa warranty policy](https://newjaisa.com/pages/warranty-policy-1)
- [Refurbo ThinkPad collection](https://refurbo.in/collections/buy-lenovo-thinkpad)
- [ReTechie Lenovo refurbished](https://retechie.com/lenovo-refurbished-laptops/)
- [Flipkart: ASUS Zenbook S16 UM5606WA](https://www.flipkart.com/asus-zenbook-s-16-amd-ryzen-9-12-core-ai-hx-370-32-gb-1-tb-ssd-windows-11-home-um5606wa-rj3310ws-thin-light-laptop/p/itma6a0e0642f03b)
- [Amazon.in: HP OmniBook Ultra 14 fd0009AU](https://www.amazon.in/HP-OmniBook-Anti-Glare-Office24-fd0009AU/dp/B0F9P8HTHY)
- [Smartprix: HP OmniBook Ultra 14 fd0009AU](https://www.smartprix.com/laptops/hp-omnibook-ultra-14-fd0009au-next-gen-ai-ppd10w57mc4x)
- [Smartprix: ThinkPad T14s Gen 6 AMD](https://www.smartprix.com/laptops/lenovo-thinkpad-t14s-gen-6-laptop-amd-ryzen-ppd1eka1x943)
- [Smartprix: RTX 5070 laptops](https://www.smartprix.com/laptops/nvidia-geforce-rtx-5070-laptops-list)
