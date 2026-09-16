# Kindling Product Specification

**Working product name:** Kindling  
**App Store title:** Kindling: Travel Memory Map  
**Subtitle:** Relive trips from your photos  
**Tagline:** Remember where life happened.  
**Platform:** Native iPhone app, Swift and SwiftUI, iOS 17+  
**Document status:** Locked product direction; implementation source of truth  
**Last updated:** 2026-09-16  
**Supersedes:** The ADHD task-initiation product described in `docs/kindling-full-plan.md`

---

## 1. Executive summary

Kindling is an ADHD-friendly visual memory companion that turns scattered travel photos into an interactive map of a person's life.

The product is for people who take many photos, remember fragments, and rarely maintain a conventional journal. A user selects photos from a past trip; Kindling groups them into moments and places, asks optional low-effort memory prompts, creates a visual Memory Trail, and resurfaces forgotten moments later as Postcards From Your Past.

Kindling is not a planner, itinerary builder, task manager, timer, public social network, diagnostic tool, or ADHD treatment. It is a private memory product designed around working-memory friction, time blindness, abandoned journals, and “out of sight, out of mind.” Travel is the initial acquisition wedge because it has clear App Store search demand, emotionally valuable source material, and naturally shareable outputs. The underlying long-term asset is the user's private Memory Atlas.

The first-session promise is:

> Pick a trip from your camera roll and receive a beautiful memory trail in minutes.

The compounding promise is:

> The more memories you kindle, the easier it becomes to find, relive, and understand where your life happened.

### 1.1 Product thesis

People do not need another blank journal. They need help reconstructing memories from evidence they already have.

Kindling succeeds if it can:

1. Create value from an existing camera roll before asking the user to build a habit.
2. Turn memory capture into tiny, optional interactions instead of writing assignments.
3. Produce an artifact worth revisiting and sharing.
4. Build a private, searchable record whose value increases over time.
5. Feel distinctly native to iOS and materially different from template travel journals and AI chat wrappers.

### 1.2 Product positioning

**Primary market position:** Travel memory map and photo journal.  
**Secondary design position:** Made for forgetful, distractible, and ADHD minds.  
**Primary App Store category:** Travel.  
**Secondary category:** Photo & Video.  
**Medical position:** None. Kindling makes no diagnostic, therapeutic, cognitive-improvement, or treatment claims.

### 1.3 The locked direction

The following decisions are locked unless user research demonstrates a serious contradiction:

- Travel memories are the initial wedge.
- The core input is the user's existing photos and optional short responses.
- The core output is a Memory Trail plus shareable postcard or recap.
- The Ember mascot is a memory keeper, not a chatbot.
- The complete emotional loop is available for free.
- User photos, locations, notes, and voice recordings remain local by default.
- No account is required for the local experience.
- The first release does not contain a task list, focus timer, streak, day planner, itinerary planner, or public feed.
- AI is not required for the core experience and cannot be the only implementation of any essential feature.

---

## 2. Context and product replacement

The repository currently implements a rejected ADHD task-initiation product. The new direction is a product replacement, not a reskin or a feature added to the old flow.

### 2.1 Reusable foundations

The following existing work should be retained where it still fits:

- Native Swift/SwiftUI application structure.
- iOS 17 minimum target.
- `KindlingCore` and `KindlingUI` local packages.
- Ember artwork, animation approach, color tokens, typography, spacing, and reusable controls.
- App Group and local-first persistence infrastructure, after its schema is replaced.
- StoreKit 2 transaction handling and paywall state handling, after products and entitlement names are replaced.
- Content-free analytics abstraction and TelemetryDeck integration.
- Landing-page project and legal-page routes, after all copy is rewritten.
- Screenshot automation, after the scenario plan and templates are replaced.
- Existing bundle identifier and App Store Connect app record, subject to Apple's metadata rules.

### 2.2 Work that must be replaced or retired

- Rescue flow, task entry, first-step generation, timers, outcomes, task shelf, and task state machine.
- Task-focused SwiftData models and all task-oriented analytics events.
- Task-session Live Activity and the current widget UI.
- Hosted task-step AI proxy, unless repurposed later behind a separately reviewed memory feature.
- `multi_task` entitlement and all related product copy.
- Current App Store name, subtitle, description, keywords, screenshots, promotional text, review notes, privacy explanations, and landing-page positioning.
- Current notification content and task-resume behavior.
- Current product plan, implementation status, and release plan as forward-looking authorities.

### 2.3 Legacy data policy

The rejected version was not publicly released, but development or TestFlight installs may contain task data.

- Create a new memory store rather than destructively transforming task entities into memory entities.
- Detect the legacy store on first launch.
- Do not display old tasks inside the new product.
- Offer a Settings section called **Previous Kindling Data** with two choices: keep it stored locally for now, or permanently delete it.
- Never delete legacy data automatically during an update.
- Remove legacy-data support only after confirming there are no public users and after at least one release cycle.

---

## 3. Goals, non-goals, and success definition

### 3.1 Product goals

1. Give a new user a meaningful artifact from an old trip within three minutes.
2. Make adding context easier than writing a conventional journal entry.
3. Make memories useful later through maps, resurfacing, and search.
4. Generate visually attractive, privacy-safe share assets that market the app naturally.
5. Establish a growing personal record that cannot be replicated by a single generic prompt.
6. Demonstrate enough native functionality and original interaction design to clearly differentiate the app during App Review.
7. Support a sustainable indie business without weakening the free core experience.

### 3.2 Business goals

- Acquire through App Store search for travel journal, photo map, trip memories, places visited, memory book, and adjacent terms.
- Acquire organically through user-created recaps and postcards.
- Convert power users who have multiple trips, want richer exports, or want cross-device continuity.
- Avoid a business model that requires a large editorial team, coaching workforce, public community, or continuous licensed content production.

### 3.3 Non-goals for v1

- Planning a future trip.
- Booking travel.
- Navigation or live turn-by-turn directions.
- Packing lists, itineraries, budgets, reservations, or expense splitting.
- Public profiles, followers, likes, comments, or a discovery feed.
- Diagnosing ADHD or improving memory as a medical claim.
- Replacing Apple Photos.
- Full photo editing.
- Automatic face identification.
- Continuous location tracking.
- A general-purpose AI assistant.
- Desktop, Android, Apple Vision, or web clients.

### 3.4 North-star outcome

**Kindled Memory:** a trip containing at least three moments that the user has opened as a Memory Trail, with at least one user-added detail or explicit “no note needed” confirmation.

The definition requires more than importing photos but does not require writing prose.

### 3.5 Activation definition

A new user is activated when, during the first session, they:

1. Select at least five photos.
2. Complete an import.
3. View the generated Memory Trail.
4. Save the trip.

Target for usability testing: median time to activation below three minutes.

### 3.6 Guardrail metrics

- Photo selection abandonment.
- Import failure rate.
- Median import processing time.
- Permission denial rate.
- Percentage of users reaching a paywall before seeing a complete Memory Trail; target is zero.
- Crash-free sessions.
- Data-loss reports.
- Share-export failure rate.
- Notification opt-out and disable rates.

---

## 4. Audience and jobs to be done

### 4.1 Primary audience

Adults who travel or take day trips, capture many photos, and do not consistently journal. They may identify as ADHD, neurodivergent, forgetful, time-blind, overwhelmed by their camera roll, or simply bad at maintaining records.

They are not looking for treatment. They want help remembering meaningful experiences without creating a new administrative burden.

### 4.2 Secondary audiences

- Couples reconstructing shared trips.
- Parents preserving family outings.
- Solo travelers who want a private record rather than a public travel feed.
- People revisiting older camera-roll archives.
- Users with chronic illness, burnout, or low energy who benefit from low-effort capture.

### 4.3 Core jobs

**When I return from a trip with hundreds of photos,** help me turn them into a coherent memory without making me write a journal.

**When I vaguely remember a place,** help me find where it was and what happened around it.

**When a memory is starting to fade,** gently bring it back with the context I previously captured.

**When I want to share a trip,** make something more meaningful than a random photo dump without requiring video-editing skills.

**When I have ADHD and cannot sustain a journaling habit,** let me preserve memories through tiny interactions that can be skipped or completed later.

### 4.4 User anxieties

- “Will this upload my photos?”
- “Will it expose precise locations?”
- “Do I have to organize everything manually?”
- “Will I lose my work if I delete a photo?”
- “Will this become another habit I fail to maintain?”
- “Will I be forced into a subscription before I see value?”
- “Does it require an account?”

Every onboarding, permission, and paywall decision must reduce these anxieties.

---

## 5. Product principles

1. **Artifact before habit.** Create something useful immediately; ask for ongoing behavior later.
2. **Evidence before blank pages.** Begin with photos, dates, and places the user already has.
3. **One small question.** Never present a form disguised as reflection.
4. **Skipping is a valid response.** No incomplete, failed, or broken-memory state.
5. **Private by default.** Sharing, cloud sync, and broader library access are explicit choices.
6. **Human memory over travel stats.** “What made you laugh?” matters more than country counts.
7. **No shame mechanics.** No streak loss, red failures, guilt copy, or “you missed yesterday.”
8. **The app explains itself through use.** Avoid long onboarding and feature tours.
9. **Native where native matters.** Photos, MapKit, widgets, haptics, share sheets, accessibility, and StoreKit should feel integrated rather than bolted on.
10. **AI assists; it does not define the product.** Deterministic and on-device paths must remain valuable.

---

## 6. Terminology

- **Memory Atlas:** the user's complete private collection of trips, places, and moments.
- **Trip:** a user-defined journey or outing containing moments.
- **Moment:** a chronological and optionally geographic cluster of related media plus user context.
- **Memory Trail:** the primary visual presentation of one trip across time and place.
- **Spark:** a single optional prompt that helps the user add context.
- **Postcard From Your Past:** a resurfaced memory presented later.
- **Recap:** a shareable static or animated artifact created from a trip.
- **Ember:** the Kindling mascot and memory keeper.
- **Import:** the act of selecting media and converting metadata into a draft trip.
- **Draft trip:** an imported trip not yet saved into the Atlas.
- **Kindling Pro:** the paid entitlement.

---

## 7. Information architecture

### 7.1 Primary navigation

The v1 app has three tabs:

1. **Atlas** — home, recent trips, resurfaced postcard, import entry point.
2. **Memories** — all trips with search, filters, archive, and favorites.
3. **Settings** — privacy, notifications, backup, purchase management, support, and legacy data.

Import is a prominent action on Atlas and Memories, not a separate permanent tab.

### 7.2 Atlas home

Priority order:

1. First-run or empty state: **Kindle a trip from your photos**.
2. Postcard From Your Past, when available.
3. Continue a draft import, when one exists.
4. Most recent Memory Trail.
5. Compact map or globe summary once the user has at least three trips.
6. Import another trip.

The screen must not become a dashboard of statistics.

### 7.3 Memories library

- List/grid toggle, with grid as default.
- Search by trip title, place label, date, tag, and note text.
- Filters: year, country/region, favorite, draft, completed, archived.
- Sorting: most recent trip date, recently edited, title.
- Each card shows cover, title, date range, place summary, and moment count.
- Missing-source-media warnings are subtle and do not make a trip appear broken.

### 7.4 Trip detail

Tabs or segmented content within a trip:

- **Trail:** chronological visual story.
- **Map:** locations and route approximation.
- **Moments:** editable moment grid/list.

The Trail is the default.

---

## 8. End-to-end user journeys

### 8.1 First launch and first memory

1. Show Ember and one sentence: “Turn scattered trip photos into a memory trail.”
2. Offer **Choose photos** and secondary **Try a sample trip**.
3. Explain before the picker: “You choose exactly what Kindling can see. Your photos stay on this device.”
4. Open the system photo picker. No full-library permission request.
5. User selects five or more photos or videos.
6. Kindling reads metadata, clusters media, and displays a lightweight progress state with Ember.
7. Present a generated draft with cover, suggested title, dates, places, moments, and map.
8. Ask one optional Spark about the most information-rich moment.
9. User saves the trip.
10. Show the completed Memory Trail.
11. Offer **Share recap** and **Remind me later**, neither preselected.

No account, notification permission, subscription screen, or broad photo permission appears before step 10.

### 8.2 Importing an old trip

- User selects media manually.
- Kindling sorts, clusters, and proposes trip boundaries.
- If media spans more than 21 days or includes a gap greater than 72 hours, the app proposes splitting into multiple trips.
- User may accept, merge, or adjust dates.
- The user can merge/split moments, change cover, edit place labels, and remove references without deleting originals.

### 8.3 Adding memory context

From a moment, the user may:

- Answer one Spark in text.
- Record a voice note.
- Add a freeform note.
- Choose “Would return,” “Once was enough,” or “Not sure.”
- Add companion names as private text tags.
- Skip permanently or ask for another Spark.

The moment editor never requires every field.

### 8.4 Resurfacing

After a trip is saved, the user can opt into Postcards From Your Past.

- Default cadence: at most one notification per week.
- First notification cannot occur less than 48 hours after opt-in.
- Notification text never contains a precise address or sensitive note.
- Opening the notification displays one memory and an optional follow-up Spark.
- Users can pause, change cadence, or disable resurfacing from the postcard and Settings.

### 8.5 Finding a place later

V1 search supports deterministic local matching across titles, place labels, tags, and notes.

Advanced natural-language search is a post-v1 Pro feature. Example queries:

- “The ramen place in Tokyo.”
- “Beaches I visited with Maya.”
- “Trips where I said I would return.”

Advanced search must clearly disclose whether a query is processed on-device or remotely before remote processing is enabled.

### 8.6 Sharing

The user chooses an artifact type:

- Static postcard.
- Map card.
- Short vertical recap video.
- Trip summary image.

Before export, the user sees a privacy preview and can remove:

- Exact map pins.
- Date.
- Companion names.
- Notes.
- Kindling branding.

Default public exports use approximate place labels and do not include exact coordinates, street addresses, hidden media, or private notes.

### 8.7 Deleting

- Removing media from a Kindling trip never deletes the original from Photos.
- Deleting a trip deletes Kindling's references, cached thumbnails, notes, voice files, generated artifacts, and cloud copies where applicable.
- A confirmation identifies exactly what will and will not be removed.
- “Delete all Kindling data” remains available without contacting support.

---

## 9. Functional requirements

### 9.1 Photo and video selection

**V1 requirements**

- Use `PhotosPicker`/PHPicker for user-selected access.
- Support HEIC, JPEG, PNG, Live Photos, and common iPhone video formats.
- Preserve original media in Photos; store references and derived thumbnails.
- Accept at least 500 selected items in one import, with graceful progress and cancellation.
- Detect duplicate asset identifiers within an import.
- Display iCloud-download progress when the original is not local.
- Allow the user to continue with available assets if some downloads fail.
- Never request full photo-library access during onboarding.

**Post-v1 optional feature**

Automatic Trip Discovery may request selected or full library access only after the user understands the manual experience. It is off by default and must remain usable with limited-library access.

### 9.2 Metadata extraction

For each selected item, attempt to read:

- Stable local asset identifier when available.
- Creation date.
- Media type and subtype.
- Duration for video.
- Pixel dimensions and orientation.
- Location coordinates, when present.
- Favorite status, when permitted.

The absence of any field must not block import.

### 9.3 Trip and moment clustering

The clustering engine must be deterministic, unit-testable, explainable, and editable.

Baseline process:

1. Sort assets by creation date, then stable identifier.
2. Build adjacency features from time gap and geographic distance.
3. Start a new moment when the previous asset is more than six hours away, or when distance and elapsed time indicate a new place.
4. Prefer grouping media within roughly one kilometer and three hours.
5. Treat media without location chronologically.
6. Propose a trip split for gaps above 72 hours, obviously separate geographic regions, or spans above 21 days.
7. Never discard an asset because confidence is low.

All thresholds are configuration values, not scattered literals. Analytics may record confidence buckets and manual correction counts, never coordinates or filenames.

### 9.4 Place resolution

- Use Apple geocoding and MapKit where possible.
- Cache resolved place labels to minimize repeated requests.
- Store coordinates independently from human-readable labels.
- Allow manual edits that are never overwritten by later resolution.
- Fall back to city/region, then date, when a venue cannot be resolved.
- Place resolution failure must not block the Memory Trail.
- Venue-level enrichment and category detection are post-v1 features.

### 9.5 Draft review

The draft screen must support:

- Suggested title and editable title.
- Cover selection.
- Date-range correction.
- Moment reorder, merge, split, and removal.
- Place-label correction.
- Map preview.
- Import cancellation without creating a saved trip.
- Autosaving the draft so the import can survive app termination.

### 9.6 Sparks

Sparks are curated prompts selected from local templates using available context.

Prompt families:

- Sensory: “What did this place sound like?”
- Emotional: “How did you feel arriving here?”
- Social: “Who made this moment better?”
- Surprise: “What was different from what you expected?”
- Recommendation: “What would you tell a friend to try?”
- Recall anchor: “What happened just before this?”
- Return intent: “Would you come back?”

Rules:

- Show one prompt at a time.
- Every prompt is skippable.
- Do not repeatedly show a skipped prompt family for the same trip.
- Do not infer emotions, diagnoses, relationships, or identities.
- Store the prompt version and displayed wording with each answer so future copy changes do not alter historical context.

### 9.7 Voice notes

- Request microphone permission only when the user taps record.
- Show recording state, elapsed time, pause, resume, playback, replace, and delete.
- Default maximum length: two minutes per note.
- Store audio locally using an efficient Apple-supported format.
- Exclude voice files from analytics and logs.
- V1 does not require transcription.
- Transcription is a later opt-in feature with a separate privacy review.

### 9.8 Memory Trail

The Trail combines:

- Cover and title.
- Date range and broad location summary.
- Chronological moments.
- Map transitions when coordinates exist.
- Media carousel within a moment.
- User notes, voice notes, and Spark responses.
- Ember commentary limited to brief structural copy, not generated emotional interpretation.

The Trail works fully offline after required thumbnails and map snapshot assets are cached. Map tiles themselves may be unavailable offline; the UI must degrade to cached snapshots and place labels.

### 9.9 Map

- Use MapKit.
- Fit all available points on first load.
- Cluster nearby pins at low zoom.
- Selecting a pin focuses the associated moment.
- Route lines are explicitly labelled as an approximate memory path; never imply GPS tracking occurred.
- The user can hide individual pins from the trip and from exports.
- Home and other sensitive locations can be marked private.

### 9.10 Recap generation

**Free**

- Standard static postcard.
- Standard map summary.
- Watermarked standard-resolution vertical recap where technically feasible.

**Pro**

- HD animated recap.
- Additional themes and pacing.
- Branding toggle.
- Longer recaps.
- Custom cover and ending card.

Generation requirements:

- Export happens on-device in v1.
- Present progress and allow cancellation.
- Clean temporary files after completion or cancellation.
- Avoid exporting hidden/private fields.
- Use licensed app-owned audio only; never copy music embedded in unrelated media unless included in the user's original video segment and legally permitted by the system export.

### 9.11 Postcards From Your Past

- Candidate selection is local and excludes recently shown, hidden, archived, and sensitive moments.
- Avoid surfacing memories the user marked “Do not resurface.”
- Record the last-presented date locally.
- Notification copy stays generic on the lock screen by default.
- The in-app postcard may reveal details after unlock.
- There is no streak or obligation to respond.

### 9.12 Search

**V1**

- Case- and diacritic-insensitive matching.
- Search title, trip notes, moment notes, Spark answers, place labels, and private companion tags.
- Filter chips for time, location, and return intent.
- All processing local.

**Pro, post-v1**

- Semantic and natural-language queries.
- Search across OCR-derived place clues when enabled.
- On-device processing preferred.
- Remote processing requires versioned explicit consent and sends the minimum text required, never photos or precise coordinates by default.

### 9.13 Widgets

The current task widget and Live Activity are retired.

Post-v1 widget candidates:

- **Memory Postcard:** a private, user-enabled resurfaced photo.
- **Atlas Count:** trips and places, without photos.
- **Continue Draft:** draft title and remaining moment count.

Photo widgets are opt-in and show a privacy warning because widget content may be visible while the device is locked.

### 9.14 Sample trip

- Bundle a clearly fictional or properly licensed sample trip.
- Sample media must be app-owned and contain no real private metadata.
- The sample demonstrates Trail, Map, Sparks, voice-note affordance, recap, and sharing.
- Sample content is never mixed into the user's Atlas unless they explicitly save a copy.
- App Review notes direct reviewers to the sample path.

---

## 10. Ember mascot specification

Ember remains a small glowing coal and becomes the user's memory keeper.

### 10.1 Responsibilities

- Explain the first import in one sentence.
- Animate while metadata is being organized.
- Deliver one Spark at a time.
- Present Postcards From Your Past.
- Celebrate completion with a quiet warm bloom.
- Explain privacy and permission states in plain language.

### 10.2 Prohibited behavior

- Ember is not an unrestricted chat interface.
- Ember does not claim to remember more than the stored data supports.
- Ember does not infer the user's emotions, diagnosis, relationships, or mental state.
- Ember does not guilt users for incomplete trips.
- Ember does not use urgency to sell Pro.

### 10.3 States

- Resting.
- Ready to import.
- Gathering metadata.
- Organizing moments.
- Asking a Spark.
- Delivering a postcard.
- Quiet celebration.
- Needs attention, used for recoverable errors without alarm styling.

All states must support Reduce Motion with a non-animated alternative.

---

## 11. Free and Pro product design

### 11.1 Free forever

- Two saved trips.
- Unlimited editing of those trips.
- Manual photo/video import.
- Automatic moment clustering.
- Map and Memory Trail.
- Text notes, Spark responses, and voice notes.
- Basic in-app search.
- Standard static postcard and map card.
- Basic resurfacing.
- Sample trip.
- Local data export and deletion.

The user must be able to complete and revisit the central emotional experience without paying.

### 11.2 Kindling Pro at launch

- Unlimited saved trips.
- HD animated recap export.
- Premium recap and postcard themes.
- Longer recap duration and branding controls.
- Expanded resurfacing controls.
- Private iCloud synchronization when the sync feature meets the release-quality gate.

### 11.3 Committed post-v1 Pro features

- Advanced natural-language memory search.
- Automatic trip discovery with optional broader library permission.
- On-device landmark, receipt, sign, and venue clue extraction.
- Shared trips with consent-based participant access.
- Yearly and thematic memory films.
- Personal, non-clinical memory patterns such as frequently revisited places or favorite trip styles.

### 11.4 Pricing

Initial US pricing target:

- Monthly: **$4.99**.
- Annual, preselected: **$29.99**.
- Early lifetime: **$59.99**.
- Annual trial: seven days.
- Regional pricing: Apple's storefront pricing, reviewed rather than hard-coded.
- Family Sharing: enabled if purchase behavior and privacy implications test correctly.

Pricing is not considered final until the launch Pro feature set is complete. Do not sell “future features.”

### 11.5 Paywall placement

Primary trigger: when a free user attempts to save a third trip, after they have already viewed its generated draft.

Secondary entry: Settings → Kindling Pro.

Optional entry: when selecting a clearly marked premium export theme.

Never show the paywall:

- Before the first completed Memory Trail.
- During photo selection.
- While a voice note is recording.
- From a resurfacing notification.
- As an interruption while editing a free trip.

### 11.6 StoreKit migration

- Replace the `multi_task` entitlement with `pro`.
- Create new identifiers rather than retaining misleading task-era identifiers:
  - `dev.aftaab.kindling.pro.monthly`
  - `dev.aftaab.kindling.pro.annual`
  - `dev.aftaab.kindling.pro.lifetime`
- Remove old task products from the new submission where App Store Connect permits; otherwise leave them unavailable for sale and exclude them from the binary's product set.
- Update the local StoreKit configuration and unit tests.
- Preserve restore, pending, Ask to Buy, refund, revocation, expiration, offline, and unknown-product handling.

---

## 12. Data model

Use a new `SchemaV2` and a new store file, tentatively `KindlingMemory.store`. The model container remains in the App Group only if a shipping extension requires it. If no extension ships in v1, prefer the app sandbox for the memory store and move to an App Group through an explicit migration when a widget ships.

### 12.1 `MemoryTrip`

- `id: UUID`
- `title: String`
- `statusRaw: String` — draft, complete, archived
- `sourceRaw: String` — manualSelection, sample, automaticDiscovery
- `startDate: Date?`
- `endDate: Date?`
- `coverMediaReferenceID: UUID?`
- `summaryPlaceText: String?`
- `isFavorite: Bool`
- `isSensitive: Bool`
- `createdAt: Date`
- `updatedAt: Date`
- Relationship: moments, cascade delete
- Relationship: import batch, nullify
- Index intent: status, start date, updated date

### 12.2 `MemoryMoment`

- `id: UUID`
- `trip: MemoryTrip?`
- `title: String?`
- `capturedAt: Date?`
- `endCapturedAt: Date?`
- `latitude: Double?`
- `longitude: Double?`
- `placeName: String?`
- `locality: String?`
- `administrativeArea: String?`
- `countryCode: String?`
- `placeSourceRaw: String` — metadata, geocoder, user
- `placeConfidence: Double?`
- `noteText: String?`
- `returnIntentRaw: String?`
- `isHidden: Bool`
- `isSensitive: Bool`
- `doNotResurface: Bool`
- `sortIndex: Int`
- `createdAt: Date`
- `updatedAt: Date`
- Relationships: media references, prompt responses, voice notes

### 12.3 `MediaReference`

- `id: UUID`
- `moment: MemoryMoment?`
- `localIdentifier: String?`
- `importedFileBookmarkOrRelativePath: String?`
- `mediaTypeRaw: String`
- `creationDate: Date?`
- `latitude: Double?`
- `longitude: Double?`
- `pixelWidth: Int?`
- `pixelHeight: Int?`
- `durationSeconds: Double?`
- `sortIndex: Int`
- `thumbnailCacheKey: String?`
- `availabilityRaw: String` — available, downloading, missing, denied
- `metadataFingerprint: String?`
- `createdAt: Date`

Original image bytes are not stored in SwiftData.

### 12.4 `PromptResponse`

- `id: UUID`
- `moment: MemoryMoment?`
- `promptKey: String`
- `promptVersion: Int`
- `promptTextSnapshot: String`
- `responseText: String?`
- `responseChoiceRaw: String?`
- `stateRaw: String` — answered, skipped, dismissed
- `createdAt: Date`
- `updatedAt: Date`

### 12.5 `VoiceNote`

- `id: UUID`
- `moment: MemoryMoment?`
- `relativeFilePath: String`
- `durationSeconds: Double`
- `createdAt: Date`
- `updatedAt: Date`

The audio file is stored outside SwiftData with file protection. Deletion cascades to the file through an explicit cleanup service.

### 12.6 `ImportBatch`

- `id: UUID`
- `stateRaw: String` — reading, clustering, resolvingPlaces, reviewing, saved, cancelled, failed
- `selectedCount: Int`
- `processedCount: Int`
- `failureCount: Int`
- `startedAt: Date`
- `completedAt: Date?`
- `algorithmVersion: Int`
- `draftTripID: UUID?`
- `recoverableErrorCode: String?`

No filenames, coordinates, or note content are written to analytics or generic logs.

### 12.7 `GeneratedArtifact`

- `id: UUID`
- `trip: MemoryTrip?`
- `typeRaw: String` — postcard, mapCard, verticalVideo, summary
- `themeID: String`
- `privacyPresetRaw: String`
- `relativeFilePath: String?`
- `createdAt: Date`
- `expiresAt: Date?`

Generated files are cache-like unless the user explicitly saves them inside Kindling.

### 12.8 `ResurfacingRecord`

- `id: UUID`
- `momentID: UUID`
- `scheduledAt: Date?`
- `presentedAt: Date?`
- `openedAt: Date?`
- `dismissedAt: Date?`
- `sourceRaw: String` — inApp, notification

### 12.9 `PrivateTag`

- `id: UUID`
- `name: String`
- `normalizedName: String`
- Relationship to moments: many-to-many

Tags are user-authored. No automatic people recognition occurs in v1.

### 12.10 `UserPreference`

Retain a key/value preference entity for non-sensitive configuration. Sensitive consent versions receive typed accessors and explicit tests.

### 12.11 Data invariants

- Every saved non-sample trip contains at least one moment.
- Every non-empty moment contains media, a note, a voice note, or a prompt response.
- User-edited place labels are never overwritten automatically.
- Deleting a trip cascades all Kindling-owned children and files.
- Deleting a reference never deletes Photos content.
- Generated artifact privacy settings are captured at generation time.
- Entitlement state is read from StoreKit and is not persisted as authoritative application data.

---

## 13. Technical architecture

### 13.1 Targets and packages

**Application target**

- SwiftUI screens and navigation.
- PhotosPicker orchestration.
- MapKit views.
- AVFoundation recording.
- StoreKit 2.
- Notifications.
- TelemetryDeck bootstrap.

**KindlingCore**

- Versioned data schema.
- Clustering engine.
- Trip split proposal engine.
- Spark selection rules.
- Resurfacing policy.
- Export privacy rules.
- Entitlement rules.
- Content-free analytics event definitions.
- Test fixtures and sample-trip model.

**KindlingUI**

- Design tokens.
- Ember states.
- Trip cards, moment cards, prompt controls, map annotations, progress states, paywall components, and accessibility helpers.

**Optional widget extension**

- Do not ship in the first memory release unless the widget has a complete privacy-safe use case and passes lock-screen review.

### 13.2 Services

- `MediaSelectionService`
- `MediaMetadataReader`
- `ThumbnailService`
- `TripClusteringService`
- `PlaceResolutionService`
- `DraftAutosaveService`
- `VoiceNoteService`
- `ArtifactRenderer`
- `ResurfacingScheduler`
- `MemorySearchService`
- `MemoryExportService`
- `LegacyDataService`
- `StoreKitEntitlementStore`
- `AnalyticsTracking`

Each service receives protocols at the core boundary so tests do not require Photos, MapKit network responses, StoreKit, or notification authorization.

### 13.3 Concurrency

- Metadata reads and thumbnail work run off the main actor.
- SwiftData writes are isolated through a dedicated model actor or well-defined main-actor repository.
- Import cancellation propagates cooperatively.
- UI progress derives from persisted `ImportBatch` state and processed counts.
- Artifact rendering uses bounded concurrency to avoid memory pressure.
- Never keep hundreds of full-resolution images in memory simultaneously.

### 13.4 Caching

- Cache thumbnails and map snapshots, not original assets.
- Use size-bounded caches with last-access eviction.
- Exclude disposable caches and temporary exports from backup.
- Rebuild missing thumbnails when the source remains available.
- If the source is no longer available, retain notes and available cached preview according to the user's retention setting.

### 13.5 Offline behavior

Available offline after source media is local:

- Import metadata extraction.
- Clustering.
- Draft editing.
- Trail viewing.
- Notes and voice notes.
- Search.
- Static exports that do not require map tile retrieval.

May require network:

- Downloading iCloud-only originals.
- Apple place resolution.
- Fresh map tiles.
- StoreKit product loading and purchase.
- Telemetry delivery.
- Future remote semantic search.

Network absence never blocks saving a trip.

### 13.6 Minimum OS and device scope

- Minimum iOS 17.
- iPhone only for the first memory release.
- Portrait is the primary layout; landscape is not promised in v1.
- Support compact devices and current large devices.
- iPad, Mac, Watch, and Vision are roadmap decisions, not automatic Catalyst targets.

---

## 14. Privacy, security, and permissions

### 14.1 Privacy promise

> Your memories belong to you. Kindling processes your selected photos and locations on your device by default. Nothing is made public unless you choose to share it.

### 14.2 Data classification

**Highly sensitive**

- Photos and videos.
- Precise coordinates.
- Voice notes.
- Companion names.
- Freeform notes.

**Sensitive**

- Trip dates.
- Place labels.
- Search queries.
- Resurfacing history.

**Non-content operational data**

- Import count bucket.
- Processing-duration bucket.
- Feature state.
- Error code.
- App version, device class, and OS version as allowed by the analytics provider.

### 14.3 Permission sequence

**Photos**

- Start with system picker access; no broad permission prompt.
- Request selected/full library permission only for an explicitly enabled feature that requires it.

**Microphone**

- Request when recording the first voice note.
- Text and photo flows remain usable if denied.

**Notifications**

- Ask only after a trip is saved and the user chooses resurfacing.
- Provide an in-app explanation before the system dialog.

**Location**

- V1 does not request live device location.
- A future active-trip feature must request When In Use authorization contextually.
- Background location is not approved by this specification.

### 14.4 Storage security

- Apply iOS file protection to the database, voice notes, generated private artifacts, and cached previews.
- Prefer complete protection when no extension needs pre-unlock access.
- Store no secrets in UserDefaults.
- Store remote-service credentials only server-side.
- Do not include media, coordinates, notes, or voice content in crash logs.
- Redact debug descriptions in Release builds.

### 14.5 Cloud sync

Private iCloud sync is a committed Pro feature but ships only after the following are true:

- Conflict behavior is deterministic and tested.
- Deletion propagates reliably.
- Opt-out and “remove cloud copy” are implemented.
- Sync status is understandable.
- A user can continue locally during an outage.
- No public CloudKit database is used.
- Account switching and iCloud-disabled states are tested on device.

The local database remains the usable source during temporary sync failures.

### 14.6 Analytics rules

Analytics events must not contain:

- Photo or file identifiers.
- Filenames.
- Coordinates.
- Place names.
- Trip titles.
- Notes, prompt responses, tags, or search text.
- Voice-note content.

Only enumerated, reviewed parameters are accepted by the analytics API. Freeform parameter dictionaries are prohibited.

### 14.7 Export and deletion

- Provide a human-readable JSON export of user-authored data and references.
- Optionally package voice notes in a ZIP through the system share sheet.
- Data export is free, not a Pro benefit.
- Provide per-trip deletion and delete-all.
- Explain that deleting Kindling data does not delete originals in Photos.

### 14.8 Privacy manifest and App Store labels

Before TestFlight:

- Audit every SDK and required-reason API.
- Add or update `PrivacyInfo.xcprivacy` files.
- Re-answer App Store privacy labels against actual shipping code.
- Name TelemetryDeck and any future remote processor in the privacy policy.
- Remove OpenAI from disclosures if the old hosted step service is removed and no new remote AI ships.

---

## 15. Accessibility and inclusive design

- Full VoiceOver labels and logical reading order.
- Dynamic Type through accessibility sizes without clipped controls.
- Minimum 44-point targets.
- Do not rely on color alone for trip state, selection, map meaning, or paywall selection.
- Reduce Motion substitutes fades/static state for Ember pulses, map flights, and recap previews.
- Reduce Transparency-compatible surfaces.
- High-contrast map annotations.
- Captions/text alternatives for voice-note meaning where supplied by the user; transcription is not assumed.
- Haptics are supplemental and can be disabled.
- No flashing animation.
- Plain-language copy and short paragraphs.
- Spark answers support dictation through the system keyboard.
- Map content has an equivalent chronological list.

Accessibility acceptance is part of feature completion, not a final QA phase.

---

## 16. Content and copy system

### 16.1 Voice

- Warm, observant, concise.
- Curious without pretending to know the user.
- Supportive without clinical language.
- Never infantilizing.
- Never guilt-based.

### 16.2 Approved examples

- “A few moments are already taking shape.”
- “Want to add one detail before it fades?”
- “Skip this one.”
- “Your photos stay on this device.”
- “This route is an approximation based on your photos.”
- “Nothing to remember right now? Your trail is still complete.”

### 16.3 Prohibited examples

- “Fix your ADHD memory.”
- “Never forget anything again.”
- “You failed to finish this memory.”
- “Your brain needs this.”
- “AI knows how you felt.”
- “Complete your streak.”

### 16.4 Error language

Errors state:

1. What happened.
2. What remains safe.
3. What the user can do next.

Example: “Three photos are still in iCloud, so they were not added yet. Your draft is saved. Try again when you have a connection, or continue without them.”

---

## 17. Notifications and resurfacing policy

- No notification permission during first launch.
- No default daily reminders.
- Maximum default cadence: weekly.
- Quiet hours default to 9 p.m.–9 a.m. local time.
- Lock-screen copy is generic unless the user enables detailed previews.
- No notification contains exact coordinates, companion names, private notes, or inferred emotional language.
- Tapping opens directly to the postcard, after device unlock.
- Notifications are cancelled when the associated trip or moment is deleted.
- A user who ignores three consecutive postcards is offered a quiet in-app suggestion to reduce cadence; never a push asking why they stopped.

---

## 18. Analytics plan

### 18.1 Core funnel

- `app_opened`
- `onboarding_started`
- `sample_trip_opened`
- `photo_picker_opened`
- `photo_selection_completed` with count bucket
- `import_started`
- `import_completed` with duration and size buckets
- `import_failed` with enumerated error
- `draft_review_opened`
- `draft_saved`
- `memory_trail_viewed`
- `spark_presented` with prompt family only
- `spark_answered`, `spark_skipped`
- `voice_note_created` with duration bucket
- `recap_previewed`
- `recap_exported` with type/theme/privacy preset
- `share_sheet_opened`
- `resurfacing_enabled`
- `postcard_presented`, `postcard_opened`
- `search_performed` with result-count bucket only
- `third_trip_save_attempted`
- `paywall_displayed` with source
- `purchase_started`, `purchase_completed`, `purchase_cancelled`, `purchase_failed`
- `restore_started`, `restore_completed`
- `trip_deleted`
- `all_data_deleted`

### 18.2 Required parameter discipline

Every event has a typed enum and fixed parameter keys. Tests assert that known sensitive key names and arbitrary strings cannot be supplied.

### 18.3 Product questions answered

- Can users reach a useful artifact quickly?
- Does the sample trip help or distract from real import?
- Which import sizes fail or take too long?
- Do Sparks add value or cause abandonment?
- Are users revisiting trails without notifications?
- Do postcards create healthy return behavior?
- Which artifact types are exported?
- Does the two-trip free boundary produce a fair conversion moment?

### 18.4 Analytics not used for

- Building advertising profiles.
- Selling user data.
- Inferring diagnoses.
- Recording precise travel histories.
- Reconstructing individual memory content.

---

## 19. App Store and acquisition specification

### 19.1 Metadata direction

**Name:** Kindling: Travel Memory Map  
**Subtitle:** Relive trips from your photos  
**Promotional-text direction:** Turn a scattered camera roll into a private, beautiful trail of where your life happened.  
**Keyword themes:** travel journal, photo map, places visited, trip memories, memory book, travel diary, vacation photos, ADHD friendly.

Do not repeat title/subtitle terms unnecessarily in the keyword field. Re-run an ASO audit before submission.

### 19.2 Screenshot story

1. **Your trip, remembered** — completed Trail.
2. **From camera roll to memory map** — import transformation.
3. **Add one tiny detail** — Spark interaction.
4. **Find the place later** — map/search.
5. **A postcard from your past** — resurfacing.
6. **Share the story, not the clutter** — recap export.

Screenshots must show the actual shipping UI and use licensed sample media.

### 19.3 Marketing content engine

Repeatable organic formats:

- Chaotic camera roll → finished Memory Trail.
- “I imported 400 photos from Japan.”
- Forgotten place rediscovery.
- Postcard From Your Past reactions.
- ADHD-friendly journaling without a blank page.
- Building-in-public clustering and map demonstrations.
- Privacy demonstrations: selected photos, local processing, share redaction.

### 19.4 Share attribution

- Free artifact includes subtle Kindling attribution.
- Pro can remove branding.
- Attribution must not obscure the user's media.
- Shared artifacts use a landing URL or QR only when it improves acquisition and does not track the recipient without consent.

---

## 20. App Review strategy

No feature set guarantees approval. The goal is to make the product's originality and native functionality concrete and easy to verify.

### 20.1 Differentiation evidence

- User-selected PhotoKit workflow.
- Deterministic metadata clustering.
- Editable moment construction.
- MapKit-based Memory Trail.
- Voice memory capture.
- On-device recap rendering.
- Privacy-safe sharing controls.
- Longitudinal resurfacing and private Memory Atlas.
- Original Ember interaction system.

### 20.2 Review notes

Review notes should:

- Explain that the app has been fundamentally redesigned after the prior rejection.
- State that it is a travel memory product, not the earlier task-starter concept.
- Give exact steps to open the bundled sample trip.
- Explain that no account or personal photo access is required to review the complete core flow.
- Describe free versus Pro behavior and how to trigger the paywall.
- Identify any network-dependent place resolution.
- State that medical claims are not made.
- Provide working support and privacy URLs.

### 20.3 Submission prerequisites

- Remove all task-era screenshots, metadata, review notes, and binary paths.
- Verify no task text appears in localizations, accessibility labels, widgets, notifications, or paywall copy.
- Remove unused capabilities, including Live Activities if none ship.
- Provide a complete sample path.
- Test purchases against sandbox and StoreKit configuration.
- Validate privacy labels against the binary.
- Confirm products and subscriptions accurately describe current benefits.

---

## 21. Delivery phases

### Phase 0 — Product reset and technical spike

**Deliverables**

- Archive old forward-looking plans as legacy.
- Create `SchemaV2` and separate memory store.
- Replace app shell with Atlas/Memories/Settings placeholders.
- Build PhotosPicker metadata spike using representative HEIC, Live Photo, video, iCloud-only, and missing-metadata samples.
- Build clustering engine prototype with deterministic fixtures.
- Build a MapKit Trail proof of concept.
- Confirm export rendering memory usage on older supported devices.
- Decide whether the App Group remains necessary for v1.

**Exit criteria**

- Fifty-photo trip produces stable moments and a map.
- No task-era flow is reachable in the main app.
- Chosen architecture can import without full-library permission.

### Phase 1 — First complete memory loop

**Deliverables**

- Minimal onboarding.
- Manual media selection.
- Metadata extraction and progress.
- Draft persistence and recovery.
- Moment clustering.
- Draft review and editing.
- Save trip.
- Trail, Map, and Moments views.
- Bundled sample trip.

**Exit criteria**

- A fresh install can produce and reopen a Memory Trail entirely offline except for iCloud asset downloads and place labels.
- Force-quit during import or review recovers safely.

### Phase 2 — Memory enrichment

**Deliverables**

- Local Spark engine.
- Notes and return intent.
- Voice notes.
- Private tags.
- Search and filters.
- Sensitive/hidden/do-not-resurface controls.

**Exit criteria**

- Every enrichment action is optional and accessible.
- Search finds all supported local fields without transmitting queries.

### Phase 3 — Recaps and resurfacing

**Deliverables**

- Static postcard and map card.
- Vertical recap renderer.
- Privacy preview and redaction.
- Postcards From Your Past.
- Notification scheduling and settings.

**Exit criteria**

- Exported artifacts contain only fields selected in preview.
- Deleted/hidden/sensitive moments are never resurfaced incorrectly.

### Phase 4 — Monetization and operational readiness

**Deliverables**

- New Pro entitlement and StoreKit products.
- Two-trip free boundary.
- Premium export themes and HD.
- Paywall, restore, manage subscription, and purchase-state handling.
- New analytics funnel.
- Privacy manifest, privacy labels, legal copy, support content.
- New landing page, metadata, screenshots, and review notes.

**Exit criteria**

- Free user completes the entire first-trip loop without seeing a paywall.
- All StoreKit test states pass.
- No sensitive analytics payload is representable.

### Phase 5 — Beta and submission

**Deliverables**

- Internal testing with synthetic and personal libraries.
- External TestFlight cohort with at least three camera-roll sizes and multiple countries/time zones.
- Accessibility audit.
- Performance and storage audit.
- App Review sample path walkthrough.
- Submission-health validation.

**Exit criteria**

- No known data-loss, privacy, purchase, or import-blocking defects.
- Release checklist complete.

### Post-v1 roadmap order

1. Private iCloud sync.
2. Automatic trip discovery.
3. Natural-language search.
4. On-device place-clue extraction.
5. Shared trips.
6. Yearly memory films and personal patterns.
7. Privacy-safe widgets.

Roadmap order can change from evidence; the product direction does not.

---

## 22. Acceptance criteria by critical feature

### 22.1 Import

- Import succeeds with location-rich, location-free, mixed image/video, and partial-iCloud selections.
- Cancellation leaves no orphan database rows or temporary full-resolution files.
- Force-quit resumes or safely restarts from persisted state.
- Removing a reference never removes the Photos asset.

### 22.2 Clustering

- Identical ordered input and algorithm version produce identical output.
- All selected media appear exactly once unless the user removes them.
- Merge, split, and reorder persist after relaunch.
- Thresholds and trip-split proposals have unit tests at boundary values.

### 22.3 Trail and map

- Trail renders with and without location.
- Map gracefully handles one point, identical points, international date line, and widely separated points.
- Approximate routes are labelled.
- VoiceOver users can access the same moment sequence without the map.

### 22.4 Voice notes

- Denied permission does not block text notes.
- Interrupted recording produces either a playable file or no file, never corrupt persisted state.
- Deletion removes both model and file.

### 22.5 Sharing

- Privacy preview matches final output.
- Hidden and sensitive fields are excluded by default.
- Export cancellation clears temporary files.
- Share works with no third-party social app installed.

### 22.6 Resurfacing

- No notification is scheduled without opt-in.
- Deleted, archived, do-not-resurface, and sensitive moments follow policy.
- Cadence and quiet hours are honored across time-zone changes.

### 22.7 Billing

- Monthly, annual, and lifetime all grant one `pro` entitlement.
- Expiration and refund remove Pro-only creation capabilities without hiding or deleting existing user data.
- Existing premium artifacts and trips remain viewable after subscription expiration.
- Restore distinguishes success, nothing to restore, pending, and failure.
- Unknown product identifiers grant nothing.

---

## 23. Quality and performance requirements

### 23.1 Performance targets

- Cold launch to interactive Atlas: under two seconds on a representative older supported iPhone, excluding first store migration.
- Metadata clustering after metadata is available: under two seconds for 100 items and under ten seconds for 500 items on a representative device.
- Trail opens in under one second for a 100-moment trip after thumbnails are cached.
- Scrolling remains responsive while thumbnails load.
- Peak memory remains bounded during 500-item import and video export.

Targets are measured, not assumed; adjust algorithms before relaxing the user experience.

### 23.2 Reliability

- Draft autosave after every structural change.
- No single network service can block saving or viewing a trip.
- Recover from missing or revoked source-media access.
- Database migrations are covered by fixture tests.
- Destructive fallback migration is prohibited in Release builds.

### 23.3 Storage

- Show Kindling storage usage in Settings.
- Provide clear-cache without deleting memories.
- Warn before generating a large export when storage is low.
- Cache limits adapt conservatively to available capacity.

### 23.4 Battery and background work

- No continuous location.
- No background photo scanning in v1.
- Use background tasks only for user-understood, resumable work.
- Pause expensive work under Low Power Mode where appropriate.

---

## 24. Test strategy

### 24.1 Unit tests

- Clustering and split thresholds.
- Missing metadata.
- Date and distance edge cases.
- Spark selection and skip policy.
- Resurfacing eligibility.
- Export privacy presets.
- Entitlement mapping.
- Analytics payload allowlist.
- Schema invariants and deletion cleanup planning.

### 24.2 Integration tests

- SwiftData store creation and migration.
- Draft recovery.
- Voice-file lifecycle.
- Thumbnail cache lifecycle.
- Notification scheduling.
- StoreKit configuration purchases and refunds.
- Legacy-store detection.

### 24.3 UI tests

- First launch with sample trip.
- First launch with real picker cancellation.
- Import → review → save → trail.
- Merge/split moments.
- Note and voice flows.
- Search.
- Share privacy controls.
- Third-trip paywall.
- Restore purchases.
- Delete trip and delete all data.

### 24.4 Manual device matrix

- Small supported iPhone.
- Current standard iPhone.
- Current Pro Max-sized iPhone.
- Device with iCloud Photos optimization enabled.
- Device with limited Photos permission.
- Device with microphone denied.
- Offline mode.
- Low storage.
- Low Power Mode.
- Large Dynamic Type, VoiceOver, Reduce Motion, and increased contrast.
- At least three locales/time zones for date-line and travel-date validation, even before localization ships.

### 24.5 Media fixture matrix

- HEIC, JPEG, PNG.
- Live Photos.
- Portrait and landscape video.
- Slow motion and cinematic media where readable.
- Screenshots mixed into trip photos.
- No date.
- No location.
- Incorrect date.
- Duplicate selection.
- Burst-like sequences.
- iCloud-only asset.
- Deleted/revoked asset.
- 1, 5, 50, 100, and 500-item imports.

---

## 25. Risks and mitigations

### 25.1 App Review 4.3 rejection

**Risk:** The redesign is perceived as another generic photo journal or as a repackaged binary.  
**Mitigation:** Rebuild the core flow, schema, screenshots, metadata, sample content, and native feature set; explicitly document differentiation in review notes.

### 25.2 Travel-journal competition

**Risk:** The product appears interchangeable with Polarsteps, FindPenguins, or photo-map apps.  
**Mitigation:** Center reconstruction and recall, not tracking or public travel broadcasting; make Sparks, resurfacing, search, and ADHD-friendly low-effort capture visible in the first experience.

### 25.3 Photo privacy anxiety

**Risk:** Users abandon before import.  
**Mitigation:** Use selected-photo picker, local processing, concise pre-permission explanation, visible privacy controls, and no account requirement.

### 25.4 Weak retention between trips

**Risk:** Travel is infrequent.  
**Mitigation:** Import old trips, resurface memories, enable place search, support day trips, and gradually expand the Atlas without becoming a generic daily journal.

### 25.5 Import complexity and performance

**Risk:** Large libraries, iCloud assets, videos, and missing metadata make import unreliable.  
**Mitigation:** Manual selected input first, persisted import state, bounded concurrency, partial success, deterministic clustering, and strong fixture coverage.

### 25.6 Subscription value

**Risk:** Two free trips plus exports are sufficient and Pro feels unnecessary.  
**Mitigation:** Do not weaken free. Build honest power-user value through unlimited archives, premium artifacts, sync, advanced search, and shared trips. Validate annual willingness before scaling paid acquisition.

### 25.7 Sensitive resurfacing

**Risk:** A painful or private memory appears unexpectedly.  
**Mitigation:** Sensitive and do-not-resurface controls, generic notifications, no lock-screen details by default, clear pause controls, and local eligibility rules.

### 25.8 Cloud-sync data loss

**Risk:** Conflict handling damages the core asset.  
**Mitigation:** Ship local-first, defer sync until deletion/conflict/offline tests pass, maintain recoverable local state, and never silently overwrite user edits.

### 25.9 Scope creep

**Risk:** The product becomes a planner, social network, or generic AI assistant.  
**Mitigation:** Apply the non-goals and require every feature proposal to strengthen capture, recall, resurfacing, search, or sharing of memories.

---

## 26. Decision framework for future features

A proposed feature belongs only if it scores positively on at least three of these five questions and introduces no privacy blocker:

1. Does it make a memory easier to reconstruct?
2. Does it make a memory easier to find or relive?
3. Does it reduce effort for a distractible user?
4. Does it strengthen the user's compounding private asset?
5. Does it create a truthful, shareable product artifact?

Automatic rejection examples:

- General to-do lists.
- Calendar planning.
- Public popularity feeds.
- Generic chatbot tabs.
- Streak maintenance.
- Unrelated wellness content.

---

## 27. Release checklist

### Product

- [ ] First real import completes.
- [ ] Sample trip demonstrates full core value.
- [ ] Draft recovery works after force-quit.
- [ ] Trail, map, moments, notes, voice, search, share, and delete are complete.
- [ ] Free and Pro boundaries match this specification.

### Privacy and safety

- [ ] Permission prompts are contextual.
- [ ] No sensitive analytics fields are possible.
- [ ] Privacy manifest is complete.
- [ ] Privacy policy describes actual processing.
- [ ] Export redaction is verified.
- [ ] Delete-all removes local and applicable cloud data.

### Billing

- [ ] New product IDs match code, StoreKit configuration, and App Store Connect.
- [ ] Monthly, annual, lifetime, trial, restore, refund, expiration, pending, and offline paths tested.
- [ ] Subscription benefits are accurate in every localization and screenshot.

### App Store

- [ ] App name, subtitle, keywords, description, categories, promotional text, URLs, and review notes replaced.
- [ ] All screenshots use current UI and licensed media.
- [ ] Review sample path works without personal data.
- [ ] Old task products and metadata are excluded.
- [ ] Unused Live Activity and other capabilities removed.
- [ ] Submission health validation passes.

### Quality

- [ ] Core unit/integration/UI suites pass.
- [ ] Real-device matrix completed.
- [ ] VoiceOver and Dynamic Type audit completed.
- [ ] Import and export performance measured.
- [ ] No known P0/P1 defects.

---

## 28. Definition of done for the first memory release

The first memory release is done when a reviewer or new user can, without an account and without granting full photo-library access:

1. Understand the product in one screen.
2. Select trip media or open the bundled sample.
3. Receive a coherent draft made from moments and places.
4. Correct the draft without losing work.
5. Add one optional text or voice detail.
6. Save and revisit a Memory Trail.
7. View the trip on a map or equivalent accessible list.
8. Export a privacy-safe artifact.
9. Opt into a future postcard.
10. Search for the memory locally.
11. Understand what is free and what Pro adds.
12. Delete or export their Kindling data without contacting support.

If any one of these paths depends on the retired task-initiation flow, requires a generic AI response, uploads personal media without explicit consent, or presents a paywall before the first complete Trail, the release is not done.

---

## 29. One-sentence product test

Every product decision should remain compatible with this sentence:

> Kindling helps distractible minds remember where life happened by transforming scattered travel photos into a private, interactive memory map.
