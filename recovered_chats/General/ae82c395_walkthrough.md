# Walkthrough - Copy, Spellings, and Client Images Update

We have completed the execution of the updates according to the client proposal document and their 21 custom images.

## Changes Made

### 1. Data Layer
- **[properties.ts](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/lib/properties.ts)**:
  - Reduced the properties list to exactly 3 client properties:
    - **Eastbrook Residence** (`winter-park-eastbrook`)
    - **Citrus Chase** (`citrus-chase-orlando`)
    - **Longwood Residence** (`longwood-residence`)
  - Updated their location, address, beds, baths, sqft, summaries, and stats based on the exact numbers in the client's proposal.
  - Linked the 21 client images (`img-1.jpeg` through `img-21.jpeg`) as static cover and gallery assets.

### 2. Page & Copy Updates
- **[about.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/routes/about.tsx)**:
  - Corrected spelling to US English (e.g. *specialize*, *modernize*, *minimize*, *maximize*).
  - Updated Vision points to match the client proposal.
  - Set page images to use `/properties/img-18.jpeg` (hero right image) and `/properties/img-19.jpeg` (story image).
- **[what-we-do.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/routes/what-we-do.tsx)**:
  - Switched spellings to US English.
  - Replaced the hero image and services preview images with client images.
- **[index.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/routes/index.tsx)**:
  - Converted spellings to US English.
  - Set the home page hero background to `/properties/img-16.jpeg` and the showcase parallax banner to `/properties/img-17.jpeg`.
  - Configured the grid components to render only the 3 updated properties.
- **[contact.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/routes/contact.tsx)** and **[SiteFooter.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/components/SiteFooter.tsx)**:
  - Updated the office address to `9064 Woodland Forest Road, Orlando, FL 32836` and the contact email to `buyutorlando@gmail.com` to match the client's proposal.

---

## Verification & Build Results

1. **Successful Static Prerendering**:
   - The project was successfully compiled using `npm run build` and prerendered exactly **8 static pages**:
     - `/` (Home)
     - `/about` (About)
     - `/contact` (Contact)
     - `/portfolio` (Portfolio index)
     - `/what-we-do` (What We Do)
     - `/portfolio/winter-park-eastbrook` (Eastbrook Residence detail)
     - `/portfolio/citrus-chase-orlando` (Citrus Chase detail)
     - `/portfolio/longwood-residence` (Longwood Residence detail)
2. **Updated Deployment Zip**:
   - Packaged the new build files from `dist/client` directly into **`dist.zip`** in the root directory.
