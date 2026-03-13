# Raahi Shop — Google Sheet Setup Guide
## Phone se products manage karo, app auto-update ho jaayega!

---

## Step 1 — Google Sheet Banao

1. **sheets.google.com** kholo apne phone/laptop mein
2. **"+ New Spreadsheet"** click karo
3. Sheet ka naam do: **Raahi Shop Products**

---

## Step 2 — Columns Setup Karo

**Row 1 (Header)** mein exactly yeh type karo:

| A | B | C | D | E | F | G | H | I | J |
|---|---|---|---|---|---|---|---|---|---|
| name | category | price | discount_price | asin | brand | rating | review_count | description | active |

---

## Step 3 — Products Add Karo (Example)

| name | category | price | discount_price | asin | brand | rating | review_count | description | active |
|------|----------|-------|----------------|------|-------|--------|--------------|-------------|--------|
| 3M Car Polish | cleaning | 599 | 449 | B08XYZ1234 | 3M | 4.3 | 2847 | Deep shine polish | TRUE |
| Puncture Kit | tyres | 399 | 299 | B09ABC5678 | Maruti | 4.1 | 5621 | Emergency repair | TRUE |
| Car Vacuum | cleaning | 1299 | 899 | B07DEF9012 | Eureka Forbes | 4.0 | 8934 | 120W wet dry | TRUE |

### Category values (exactly yahi likhna):
- cleaning
- accessories  
- tyres
- electrical
- oils
- safety

### ASIN kahan milega?
```
Amazon pe product open karo
URL dekho: amazon.in/dp/B08XYZ1234
                        ^^^^^^^^^^
                        Yeh hai ASIN — copy karo
```

---

## Step 4 — Sheet ko Public Karo

1. **File → Share → Publish to web** click karo
2. **"Entire Document"** select karo
3. Format mein **"Comma-separated values (.csv)"** select karo
4. **"Publish"** click karo
5. Ek URL milega — copy karo

URL kuch aisa dikhega:
```
https://docs.google.com/spreadsheets/d/XXXXXXXXXX/pub?output=csv
```

---

## Step 5 — App mein URL Daalo

File kholo: `lib/services/affiliate_service.dart`

Line 28 pe apna URL daalo:
```dart
static const String _sheetCsvUrl =
    'https://docs.google.com/spreadsheets/d/XXXXXXXXXX/pub?output=csv';
```

---

## Naya Product Add Karna Ho?

```
1. Google Sheet kholo (phone se bhi ho sakta hai)
2. Nayi row add karo
3. ASIN Amazon se copy karo
4. active = TRUE rakho
5. Save — bas!

App 30 minute mein auto-update ho jaayega
Ya user sheet pull-to-refresh kare — turant update
```

## Product Temporarily Hatana Ho?

```
active column mein FALSE kar do
Product app se gayab ho jaayega
ASIN delete karne ki zaroorat nahi
```

---

## Commission Track Karna

Amazon Associates dashboard:
```
affiliate-program.amazon.in
→ Reports → Earnings
→ Dekho kitna commission aaya
```

Tracking ID: raahi-21 (ya jo tune set kiya)

---

## Estimated Earnings

| Users/month | Avg order | Commission rate | Monthly earning |
|-------------|-----------|-----------------|-----------------|
| 500 | ₹800 | 6% | ~₹24,000 |
| 1000 | ₹800 | 6% | ~₹48,000 |
| 2000 | ₹800 | 6% | ~₹96,000 |

*Amazon Associates minimum payout: ₹2,500*
*Payment: Bank transfer, 60 days after month end*
