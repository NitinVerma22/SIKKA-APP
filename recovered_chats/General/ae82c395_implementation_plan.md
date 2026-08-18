# Implementation Plan - Update Copy, Spellings, and Client Images

We will update the website content according to the client's business proposal document and their 21 custom images. The site will keep the "Makaan Ventures" brand, but the copy will be updated to reflect the actual project financials/addresses, use US English spellings, reduce the portfolio to the 3 client properties, and replace all stock/dummy images.

## User Review Required

> [!IMPORTANT]
> - **Properties count reduced to 3**: As requested, we will remove the 3 dummy properties (The Blue Cottage, Lakeside Bungalow, Midcentury Restoration) and only render the 3 client properties (Eastbrook Residence, Citrus Chase, Longwood Residence) throughout the site.
> - **Spelling conversion**: We will change spelling throughout the site to US English (e.g., *maximise* -> *maximize*, *minimise* -> *minimize*, *modernise* -> *modernize*, *favourite* -> *favorite*).
> - **Static images**: The 21 client images will be referenced as `/properties/img-*.jpeg` directly from the `public/properties` folder which we set up.

## Proposed Changes

---

### 1. Data Layer

#### [MODIFY] [properties.ts](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/lib/properties.ts)
- Filter the `properties` array to only contain the 3 client projects: `winter-park-eastbrook`, `citrus-chase-orlando`, and `longwood-residence`.
- Update the stats, addresses, and details for these 3 properties to match the exact figures in the proposal doc.
- Remove all Unsplash image fallback URLs and reference the client images `/properties/img-1.jpeg` through `/properties/img-15.jpeg` for the property covers and galleries.

---

### 2. Routes & Pages

#### [MODIFY] [about.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/routes/about.tsx)
- Convert British spellings to US English.
- Update Vision points list:
  - `Hospitality & Resort` -> `Hospitality & Resort Development`
  - `Institutional Partnerships` -> `Institutional Investment Partnerships`
- Update page images to use `/properties/img-18.jpeg` (hero right image) and `/properties/img-19.jpeg` (story section image).

#### [MODIFY] [what-we-do.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/routes/what-we-do.tsx)
- Convert British spellings to US English.
- Update hero page image to `/properties/img-20.jpeg`.
- Update the four services images in the list to use `/properties/img-1.jpeg`, `/properties/img-6.jpeg`, `/properties/img-11.jpeg`, and `/properties/img-21.jpeg`.

#### [MODIFY] [index.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/routes/index.tsx)
- Convert British spellings to US English.
- Update Home page hero background image to `/properties/img-16.jpeg`.
- Update the showcase parallax banner image to `/properties/img-17.jpeg`.
- Ensure the featured portfolio grid only renders the 3 active properties.

#### [MODIFY] [SiteHeader.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/components/SiteHeader.tsx) and [SiteFooter.tsx](file:///c:/Users/Nitin/Downloads/Makaan%20Value%20Builders/src/components/SiteFooter.tsx)
- Check for and convert any British English spellings to US English (e.g. `maximise`, `minimise`).

---

## Verification Plan

### Manual Verification
1. Run `npm run dev` and open the site in a browser.
2. Confirm the About page and home page have client text, US English spellings, and client images.
3. Verify that the portfolio section and detail pages render only the 3 updated properties with correct pricing and galleries.
4. Run `npm run build` to generate the new production static build under `dist` and verify the prerendering completes successfully.
5. Package the updated build into `dist.zip`.
