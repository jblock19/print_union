"use client";

import { useEffect, useMemo, useState } from "react";

const storageKey = "community-flyer-next-vibes-v4";
const imageDbName = "community-flyer-images";
const imageStoreName = "flyer-images";
const flyerImageFields = ["avatarImage", "communityImage", "myFlyerImage"];
const generatedBodyRows = ["title", "whenWhere", "art", "whatWeDo", "firstTimerNote"];
const flyerModes = {
  create: "create",
  useOwn: "use-own"
};

const vibeExamples = {
  "70s-community": {
    category: "friendships",
    postedDaysAgo: 1,
    signaturePrefix: "Made by",
    communityName: "Soft Power Girls Club",
    communityLine:
      "A city girls club for new friends, small plans, shared tools, soft ambition, and showing up without performing cool.",
    title: "Girls Who Make The Plan",
    whenWhereLine: "Every other Thursday, 6:30 PM / Borrowed cafe table, east side",
    mainInvitation: "Come solo, leave known.",
    whatWeDo:
      "We host low-pressure meetups: co-working corners, closet swaps, skill shares, cafe walks, and practical pep talks.",
    firstTimerNote:
      "You can arrive alone, quiet, late, or overdressed. Someone will say hi, and nobody has to pitch themselves.",
    defaultImage: "/community-girls-club.jpg",
    imageAlt: "Young women and friends gathering around a city table with notebooks and coffee",
    photoDirection:
      "Realistic young-city girls club photo: friends around a cafe or studio table, tote bags, notebooks, phone on table, warm but not influencer-polished."
  },
  "group-chat-flyer": {
    category: "activity-partners",
    postedDaysAgo: 2,
    signaturePrefix: "From the chat",
    communityName: "After Work Stretch Chat",
    communityLine:
      "A flexible yoga group for tight hips, tired brains, borrowed mats, and friends who need the plan to feel easy.",
    title: "Stretch, Then Stay",
    whenWhereLine: "Wednesdays after work / Community studio near the train",
    mainInvitation: "Mats can be borrowed.",
    whatWeDo:
      "We meet after work for gentle flow, floor stretches, and ten quiet minutes before anyone decides about dinner.",
    firstTimerNote:
      "No matching set required. Come stiff, distracted, or brand new; every pose has an easier option.",
    defaultImage: "/community-stretch-chat.jpg",
    imageAlt: "Small yoga group stretching on mats in a bright city studio",
    photoDirection:
      "Realistic casual yoga group photo: mixed friends on mats in a community studio or rooftop room, soft light, relaxed not luxury-wellness."
  },
  "xerox-punk": {
    category: "grow-and-learn",
    postedDaysAgo: 5,
    signaturePrefix: "Open at",
    communityName: "Pocket Studio Hours",
    communityLine:
      "A tiny creative studio night for half-built ideas, rough drafts, shared chargers, and people making after work.",
    title: "Bring The Unfinished Thing",
    whenWhereLine: "First Friday, 7 PM / Pocket Studio, back table",
    mainInvitation: "No portfolio energy.",
    whatWeDo:
      "We put phones down, set a timer, make quietly, ask for one useful note, and leave with the next step written down.",
    firstTimerNote:
      "Bring a sketch, deck, beat, draft, moodboard, or blank page. Borrow a pencil and start from there.",
    defaultImage: "/community-open-studio.jpg",
    imageAlt: "People working at a small creative studio table with laptops, paper, and supplies",
    photoDirection:
      "Realistic open studio photo: young adults at a shared table with paper, laptops, pens, tape, and snacks; useful mess, not art-school gallery."
  },
  "riso-indie-social": {
    category: "friendships",
    postedDaysAgo: 3,
    signaturePrefix: "From the folks at",
    communityName: "Sidewalk Supper Club",
    communityLine:
      "A rotating dinner table for young neighbors, first apartments, new recipes, shared playlists, and low-stakes hosting.",
    title: "Bring A Dish Or A Story",
    whenWhereLine: "Sunday, 5 PM / Park table or borrowed stoop",
    mainInvitation: "Store-bought counts.",
    whatWeDo:
      "We claim a park table, stoop, or borrowed studio, eat what appears, and trade city tips with people we almost know.",
    firstTimerNote:
      "Bring food if you can, or napkins, ice, a playlist, or just yourself. The point is the table.",
    defaultImage: "/community-supper-club.jpg",
    imageAlt: "Young neighbors sharing food at a casual outdoor city table",
    photoDirection:
      "Realistic casual supper club photo: folding table or park table, shared dishes, paper plates, friends arriving, city evening light."
  },
  "90s-block-party": {
    category: "activity-partners",
    postedDaysAgo: 4,
    signaturePrefix: "Hosted by",
    communityName: "Austin Photo Walkers",
    communityLine:
      "Phone-camera people, film-camera people, street-detail people, and curious walkers learning to look slowly together.",
    title: "Come Walk With Us",
    whenWhereLine: "Saturday, 10 AM / Meet outside the corner coffee shop",
    mainInvitation: "No fancy camera needed.",
    whatWeDo:
      "We walk a few blocks, trade rolls and tips, compare cameras, and notice small Austin details that reward a slower pace.",
    firstTimerNote:
      "Come with any camera, or no camera yet. New people usually pair up with someone who knows the route.",
    defaultImage: "/community-austin-film-shooters.jpg",
    imageAlt: "Vintage film camera held during a neighborhood photo walk",
    photoDirection:
      "Realistic photo walk image: hands holding a film camera, sidewalks or storefronts nearby, casual group energy, warm daylight."
  },
  "00s-zine-web": {
    category: "activity-partners",
    postedDaysAgo: 6,
    signaturePrefix: "From the folks at",
    communityName: "Creek Dip Walkers",
    communityLine:
      "A hiking and water group for bus-accessible trails, creek dips, sunscreen sharing, and getting outside without buying all the gear.",
    title: "Find The Water",
    whenWhereLine: "Sunday morning, before it gets hot / Transit-friendly trailhead",
    mainInvitation: "No car, no problem.",
    whatWeDo:
      "We pick an easy route, post the transit plan, walk at a talking pace, and stop near water when the city gets too hot.",
    firstTimerNote:
      "Bring water and shoes that can get dusty. We wait at turns, share shade, and keep the route beginner-friendly.",
    defaultImage: "/community-creek-dip-walkers.jpg",
    imageAlt: "Small group walking near an urban creek or waterfront trail",
    photoDirection:
      "Realistic hiking/water meetup photo: young city group on a greenbelt, creek, lake edge, or waterfront path, backpacks and water bottles, relaxed not extreme-outdoor."
  },
  "civic-now": {
    category: "chat-and-vibe",
    postedDaysAgo: 1,
    signaturePrefix: "From the chat",
    communityName: "Sunset Swap Chat",
    communityLine:
      "A neighborhood swap thread for plant cuttings, book piles, spare chairs, extra jackets, and easy five-minute hellos.",
    title: "Reply Maybe, Drop By",
    whenWhereLine: "Tonight near sunset / Folding table by the front gate",
    mainInvitation: "No RSVP pressure.",
    whatWeDo:
      "We post what we are bringing, set up a small table near sunset, and let useful extras find new homes.",
    firstTimerNote:
      "Come empty-handed if you want. Lurkers are welcome, names are learned slowly, and leaving after five minutes is normal.",
    defaultImage: "/community-sunset-swap-chat.jpg",
    imageAlt: "Neighbors gathering around a clothing and household swap table",
    photoDirection:
      "Realistic neighborhood swap photo: folding table, clothes, books, plants, neighbors drifting through, casual golden-hour group-chat energy."
  }
};

function getFlyerCopy(vibeKey) {
  const example = vibeExamples[vibeKey] || vibeExamples["70s-community"];

  return {
    category: example.category,
    postedDaysAgo: example.postedDaysAgo,
    signaturePrefix: example.signaturePrefix,
    communityName: example.communityName,
    communityLine: example.communityLine,
    title: example.title,
    whenWhereLine: example.whenWhereLine,
    mainInvitation: example.mainInvitation,
    whatWeDoLabel: "What we do",
    whatWeDo: example.whatWeDo,
    firstTimerNoteLabel: "First-timer note",
    firstTimerNote: example.firstTimerNote
  };
}

const defaultFlyer = {
  vibe: "70s-community",
  flyerMode: flyerModes.create,
  layoutMode: "classic",
  rowOrder: ["header", "signature", "myFlyer", "title", "whenWhere", "art", "whatWeDo", "firstTimerNote"],
  hiddenRows: ["myFlyer"],
  colorMood: "classic",
  accentOne: "#f45b93",
  accentTwo: "#e9a72d",
  accentThree: "#277a55",
  backgroundColor: "",
  textColor: "",
  outlineColor: "",
  textBoxColor: "",
  depth: "soft",
  avatarImage: "",
  myFlyerImage: "",
  communityImage: "",
  ...getFlyerCopy("70s-community")
};

const colorMoods = [
  {
    id: "classic",
    label: "Classic",
    description: "Primary colors plus useful brights.",
    colors: [
      { name: "Ink black", value: "#111111" },
      { name: "Paper cream", value: "#f7f1df" },
      { name: "Signal red", value: "#e1261c" },
      { name: "Marigold", value: "#e9a72d" },
      { name: "Royal blue", value: "#2457a6" },
      { name: "Fern", value: "#277a55" },
      { name: "Hot rose", value: "#f45b93" },
      { name: "Violet", value: "#8b5cf6" },
      { name: "Trail rust", value: "#c76a2b" },
      { name: "Chat teal", value: "#18a8b5" },
      { name: "White", value: "#ffffff" }
    ]
  },
  {
    id: "pastel",
    label: "Pastel",
    description: "Soft, airy, community-board color.",
    colors: [
      { name: "Petal pink", value: "#f7a8c8" },
      { name: "Butter yellow", value: "#f8df72" },
      { name: "Mint", value: "#8ed8b4" },
      { name: "Sky", value: "#86c8f2" },
      { name: "Lilac", value: "#c5a3ff" },
      { name: "Peach", value: "#f6b28d" },
      { name: "Powder blue", value: "#b7d8ff" },
      { name: "Soft coral", value: "#f28f8f" },
      { name: "Pistachio", value: "#b7d96f" },
      { name: "Warm paper", value: "#fff1cf" },
      { name: "White", value: "#ffffff" }
    ]
  },
  {
    id: "gothic",
    label: "Gothic",
    description: "Dark ink, bone, bruised jewel tones.",
    colors: [
      { name: "Black", value: "#080808" },
      { name: "Bone", value: "#e7dfcf" },
      { name: "Blood red", value: "#9f1118" },
      { name: "Deep violet", value: "#3b1768" },
      { name: "Oxide green", value: "#16483a" },
      { name: "Midnight blue", value: "#102a54" },
      { name: "Charcoal", value: "#2d2b2f" },
      { name: "Silver", value: "#a8a4a0" },
      { name: "Poison pink", value: "#d91d72" },
      { name: "Brass", value: "#a97922" },
      { name: "White", value: "#ffffff" }
    ]
  },
  {
    id: "earth",
    label: "Earth",
    description: "Clay, moss, lake, ochre, charcoal.",
    colors: [
      { name: "Clay", value: "#a84f2d" },
      { name: "Rust", value: "#c76a2b" },
      { name: "Ochre", value: "#c9962f" },
      { name: "Moss", value: "#586f3d" },
      { name: "Pine", value: "#245442" },
      { name: "Lake", value: "#4169a8" },
      { name: "Silt", value: "#a59678" },
      { name: "Charcoal", value: "#30302a" },
      { name: "Adobe", value: "#d58b63" },
      { name: "Field green", value: "#7e9c58" },
      { name: "White", value: "#ffffff" }
    ]
  }
];

const backgroundColors = [
  { name: "White", value: "#ffffff" },
  { name: "Paper", value: "#fbfaf5" },
  { name: "Cream", value: "#f7f1df" },
  { name: "Warm yellow", value: "#fff1cf" },
  { name: "Blush", value: "#ffe7ed" },
  { name: "Mint", value: "#e5f6ec" },
  { name: "Sky", value: "#e6f3ff" },
  { name: "Lilac", value: "#eee6ff" },
  { name: "Charcoal", value: "#2d2b2f" },
  { name: "Black", value: "#080808" },
  { name: "Earth", value: "#efe4d1" }
];

const inkColors = [
  { name: "Black", value: "#111111" },
  { name: "Soft black", value: "#2d2b2f" },
  { name: "White", value: "#ffffff" },
  { name: "Cream", value: "#f7f1df" },
  { name: "Red", value: "#e1261c" },
  { name: "Blue", value: "#2457a6" },
  { name: "Green", value: "#277a55" },
  { name: "Pink", value: "#f45b93" },
  { name: "Yellow", value: "#e9a72d" },
  { name: "Teal", value: "#18a8b5" },
  { name: "Violet", value: "#8b5cf6" }
];

const accentSlots = [
  { key: "accentOne", label: "Highlight 1" },
  { key: "accentTwo", label: "Highlight 2" },
  { key: "accentThree", label: "Highlight 3" }
];

const depthOptions = [
  { id: "flat", label: "Flat", description: "No extra shadows or lift." },
  { id: "soft", label: "Soft", description: "Gentle default depth." },
  { id: "bold", label: "Bold", description: "Stronger shadows and offsets." }
];

const signatureOptions = [
  "Hosted by",
  "Presented by",
  "From the folks at",
  "A gathering of",
  "A gather of",
  "Put together by",
  "Brought to you by",
  "Organized by",
  "Started by",
  "Led by",
  "Opened by",
  "From the chat",
  "Called by",
  "Open at",
  "Made with",
  "Made by",
  "Made for",
  "Built by"
];

const categoryOptions = [
  {
    id: "friendships",
    internalLabel: "Friendships",
    displayLabel: "Friends",
    icon: "/classifieds-icons/categories/friendships.svg"
  },
  {
    id: "activity-partners",
    internalLabel: "Activity Partners",
    displayLabel: "Do Fun Things",
    icon: "/classifieds-icons/categories/activity-partners.svg"
  },
  {
    id: "grow-and-learn",
    internalLabel: "Grow and Learn",
    displayLabel: "Nerd Out",
    icon: "/classifieds-icons/categories/grow-and-learn.svg"
  },
  {
    id: "chat-and-vibe",
    internalLabel: "Chat and Vibe",
    displayLabel: "Get Chatty",
    icon: "/classifieds-icons/categories/chat-and-vibe.svg"
  },
  {
    id: "romance",
    internalLabel: "Romance",
    displayLabel: "Romance",
    icon: "/classifieds-icons/categories/romance.svg"
  }
];

function normalizeCategoryId(value) {
  const normalizedValue = String(value || "").trim().toLowerCase();
  const category = categoryOptions.find((option) => {
    return [option.id, option.internalLabel, option.displayLabel].some(
      (label) => label.toLowerCase() === normalizedValue
    );
  });

  return category?.id || categoryOptions[0].id;
}

function getCategory(value) {
  const categoryId = normalizeCategoryId(value);
  return categoryOptions.find((option) => option.id === categoryId) || categoryOptions[0];
}

function normalizeColorMoodId(value) {
  const normalizedValue = String(value || "").trim().toLowerCase();
  return colorMoods.some((mood) => mood.id === normalizedValue) ? normalizedValue : colorMoods[0].id;
}

function getColorMood(value) {
  const moodId = normalizeColorMoodId(value);
  return colorMoods.find((mood) => mood.id === moodId) || colorMoods[0];
}

function normalizeWhenWhereLine(flyer) {
  const whenWhereLine = String(flyer.whenWhereLine || "").trim();
  if (whenWhereLine) return whenWhereLine;

  return [flyer.whenLine, flyer.whereLine]
    .map((value) => String(value || "").trim())
    .filter(Boolean)
    .join(" / ");
}

function normalizeFlyerMode(value, myFlyerImage = "") {
  if (value === flyerModes.create || value === flyerModes.useOwn) return value;
  return String(myFlyerImage || "").trim() ? flyerModes.useOwn : flyerModes.create;
}

function normalizeDepth(value) {
  return depthOptions.some((option) => option.id === value) ? value : "soft";
}

function normalizeFlyer(flyer) {
  const myFlyerImage = String(flyer.myFlyerImage || "");
  const hiddenRows = normalizeHiddenRows(flyer.hiddenRows);
  const normalizedHiddenRows = myFlyerImage.trim()
    ? hiddenRows
    : hiddenRows.includes("myFlyer")
      ? hiddenRows
      : [...hiddenRows, "myFlyer"];

  return {
    ...flyer,
    flyerMode: normalizeFlyerMode(flyer.flyerMode, myFlyerImage),
    depth: normalizeDepth(flyer.depth),
    myFlyerImage,
    rowOrder: normalizeRowOrder(flyer.rowOrder),
    hiddenRows: normalizedHiddenRows,
    category: normalizeCategoryId(flyer.category),
    colorMood: normalizeColorMoodId(flyer.colorMood),
    whenWhereLine: normalizeWhenWhereLine(flyer),
    whatWeDoLabel: String(flyer.whatWeDoLabel || "What we do").trim() || "What we do",
    firstTimerNoteLabel: String(flyer.firstTimerNoteLabel || "First-timer note").trim() || "First-timer note",
    postedDaysAgo: Number.isFinite(Number(flyer.postedDaysAgo)) ? Number(flyer.postedDaysAgo) : 1
  };
}

function formatPostedDays(days) {
  const safeDays = Math.max(0, Math.round(Number(days) || 0));
  return safeDays === 0 ? "Today" : `${safeDays}D AGO`;
}

const vibes = [
  {
    key: "70s-community",
    name: "Soft Club",
    description: "Warm, easy-entry poster.",
    accents: ["#f45b93", "#e9a72d", "#277a55"]
  },
  {
    key: "group-chat-flyer",
    name: "Group Chat",
    description: "Casual chat-style invite.",
    accents: ["#8b5cf6", "#18a8b5", "#f6c343"]
  },
  {
    key: "xerox-punk",
    name: "Studio Note",
    description: "Spare ink, bright note.",
    accents: ["#111111", "#f7f1df", "#e1261c"]
  },
  {
    key: "riso-indie-social",
    name: "Riso Table",
    description: "Soft ink for gatherings.",
    accents: ["#00a6c8", "#ff3ea5", "#f6d84a"]
  },
  {
    key: "90s-block-party",
    name: "Street Stack",
    description: "Bold neighborhood type.",
    accents: ["#e1261c", "#e9a72d", "#2457a6"]
  },
  {
    key: "00s-zine-web",
    name: "Trail Zine",
    description: "Map-note outdoor texture.",
    accents: ["#277a55", "#c76a2b", "#4169a8"]
  },
  {
    key: "civic-now",
    name: "Clean Civic",
    description: "Calm noticeboard layout.",
    accents: ["#2457a6", "#e9a72d", "#10b981"]
  }
];

const vibeTheory = {
  "70s-community": {
    title: "Why Soft Club works",
    body:
      "Soft Power Girls Club gets a friendly civic-poster read: the title \"Girls Who Make The Plan\" is heavy and unpretentious, with only a tiny soft shadow. The girls-club photo sits in a rounded frame with one clipped corner, while the GC mark, pale pink field, and light green shadow make the flyer feel made by people. The excitement comes from color and scale; the ease comes from keeping the borders thin, the shapes soft, and the layout orderly."
  },
  "group-chat-flyer": {
    title: "Why Group Chat works",
    body:
      "After Work Stretch Chat is designed like a plan that could have come from someone's phone: \"Stretch, Then Stay\" uses big plain type with no dramatic effect. The yoga photo, signature block, copy cards, and ribbon all use rounded bubble corners, including one little tail-like corner. It feels inviting because the shapes say casual message thread, while the quiet border and soft accents keep the wellness energy from turning glossy."
  },
  "xerox-punk": {
    title: "Why Studio Note works",
    body:
      "Pocket Studio Hours uses \"Bring The Unfinished Thing\" as a direct studio-wall note, not a polished portfolio headline. The open-studio image is slightly desaturated inside a nearly square-corner frame, with thin rules, a faint paper-line background, and small offset shadows. The flyer has enough grit to make making feel possible, but the cleaner borders and roomy rows stop it from becoming fake punk noise."
  },
  "riso-indie-social": {
    title: "Why Riso Table works",
    body:
      "Sidewalk Supper Club turns \"Bring A Dish Or A Story\" into a print-table headline, with slight misregistered color shadows that echo risograph ink. The supper-club photo gets a light framed treatment, dot texture, crop-mark logic, and small colored shadows on the image and copy cards. It creates appetite and warmth through ink, grain, and overlap, but stays easy because the structure is still a simple invitation, photo, and two-note layout."
  },
  "90s-block-party": {
    title: "Why Street Stack works",
    body:
      "Austin Photo Walkers uses \"Come Walk With Us\" as a bold neighborhood headline, stacked large with a small blue shadow for movement. The camera-walk image gets a straight-edged frame, a modest yellow offset shadow, side color bars, and slightly squared copy cards. It feels active and public without shouting because the 90s flyer cues are limited to type weight, stripes, and shadow, not a full nostalgia pileup."
  },
  "00s-zine-web": {
    title: "Why Trail Zine works",
    body:
      "Creek Dip Walkers makes \"Find The Water\" feel like a field note: heavy plain type, a tiny shadow, and a lightly rotated signature/image treatment. The creek-walk photo sits in a rounded frame over notebook-like blue lines and a soft vertical guide stripe. The design gives the hike a handmade, bus-route sincerity, while the thin borders and gentle shadows keep it beginner-friendly instead of scrappy for scrappy's sake."
  },
  "civic-now": {
    title: "Why Clean Civic works",
    body:
      "Sunset Swap Chat treats \"Reply Maybe, Drop By\" like a useful neighborhood notice: direct title, no title shadow, and a calm modular layout. The swap-table photo is rounded but plain, paired with a plus-sign community mark, a soft top band, and clean one-pixel borders. It creates trust by looking organized and current, with just enough accent color to feel social rather than municipal."
  }
};

const rowLabels = {
  header: "Header",
  signature: "Signature",
  myFlyer: "My flyer",
  title: "Title",
  whenWhere: "When / Where",
  art: "Image"
};

const noteRowKeys = ["whatWeDo", "firstTimerNote"];
const requiredRowKeys = new Set(["header", "signature"]);

function getRowLabel(rowKey, flyer) {
  if (rowKey === "notes") return "Notes";
  if (rowKey === "whatWeDo") return String(flyer.whatWeDoLabel || "What we do").trim() || "What we do";
  if (rowKey === "firstTimerNote") {
    return String(flyer.firstTimerNoteLabel || "First-timer note").trim() || "First-timer note";
  }

  return rowLabels[rowKey] || rowKey;
}

function getTitleFitClass(title) {
  const length = title.trim().length;
  if (length > 58) return "is-title-xs";
  if (length > 44) return "is-title-sm";
  if (length > 32) return "is-title-md";
  return "";
}

function normalizeRowOrder(rowOrder) {
  if (!Array.isArray(rowOrder)) return defaultFlyer.rowOrder;

  const knownRows = new Set(defaultFlyer.rowOrder);
  const expandedRows = rowOrder.flatMap((rowKey) => (rowKey === "copy" ? ["whatWeDo", "firstTimerNote"] : rowKey));
  const cleanedRows = expandedRows.filter(
    (rowKey, index) => knownRows.has(rowKey) && expandedRows.indexOf(rowKey) === index
  );
  const missingRows = defaultFlyer.rowOrder.filter((rowKey) => !cleanedRows.includes(rowKey));
  if (missingRows.includes("header")) {
    cleanedRows.unshift("header");
  }
  if (missingRows.includes("myFlyer")) {
    const signatureIndex = cleanedRows.indexOf("signature");
    const titleIndex = cleanedRows.indexOf("title");
    const insertIndex = signatureIndex >= 0 ? signatureIndex + 1 : titleIndex >= 0 ? titleIndex : cleanedRows.length;
    cleanedRows.splice(insertIndex, 0, "myFlyer");
  }
  if (missingRows.includes("whenWhere")) {
    const titleIndex = cleanedRows.indexOf("title");
    const artIndex = cleanedRows.indexOf("art");
    const insertIndex = titleIndex >= 0 ? titleIndex + 1 : artIndex >= 0 ? artIndex : cleanedRows.length;
    cleanedRows.splice(insertIndex, 0, "whenWhere");
  }

  const remainingMissingRows = defaultFlyer.rowOrder.filter((rowKey) => !cleanedRows.includes(rowKey));
  return [...cleanedRows, ...remainingMissingRows];
}

function normalizeHiddenRows(hiddenRows) {
  if (!Array.isArray(hiddenRows)) return [];

  const knownRows = new Set(defaultFlyer.rowOrder);
  const expandedRows = hiddenRows.flatMap((rowKey) => (rowKey === "copy" ? ["whatWeDo", "firstTimerNote"] : rowKey));
  return expandedRows.filter(
    (rowKey, index) => knownRows.has(rowKey) && !requiredRowKeys.has(rowKey) && expandedRows.indexOf(rowKey) === index
  );
}

function getFlyerMetadata(flyer) {
  const metadata = { ...flyer };
  flyerImageFields.forEach((field) => {
    delete metadata[field];
  });
  return metadata;
}

function saveFlyerMetadata(flyer) {
  const payload = JSON.stringify(getFlyerMetadata(flyer));

  try {
    window.localStorage.setItem(storageKey, payload);
  } catch (error) {
    console.warn("Could not save flyer metadata.", error);
    try {
      window.localStorage.removeItem(storageKey);
      window.localStorage.setItem(storageKey, payload);
    } catch (retryError) {
      console.warn("Could not recover flyer metadata storage.", retryError);
    }
  }
}

function openFlyerImageDb() {
  if (typeof window === "undefined" || !window.indexedDB) return Promise.resolve(null);

  return new Promise((resolve, reject) => {
    const request = window.indexedDB.open(imageDbName, 1);

    request.addEventListener("upgradeneeded", () => {
      if (!request.result.objectStoreNames.contains(imageStoreName)) {
        request.result.createObjectStore(imageStoreName);
      }
    });
    request.addEventListener("success", () => resolve(request.result));
    request.addEventListener("error", () => reject(request.error));
  });
}

async function loadSavedFlyerImages() {
  const db = await openFlyerImageDb();
  if (!db) return {};

  return new Promise((resolve, reject) => {
    const transaction = db.transaction(imageStoreName, "readonly");
    const store = transaction.objectStore(imageStoreName);
    const images = {};

    flyerImageFields.forEach((field) => {
      const request = store.get(field);
      request.addEventListener("success", () => {
        if (request.result) images[field] = request.result;
      });
    });

    transaction.addEventListener("complete", () => {
      db.close();
      resolve(images);
    });
    transaction.addEventListener("error", () => {
      db.close();
      reject(transaction.error);
    });
  });
}

async function saveFlyerImages(flyer) {
  const db = await openFlyerImageDb();
  if (!db) return;

  return new Promise((resolve, reject) => {
    const transaction = db.transaction(imageStoreName, "readwrite");
    const store = transaction.objectStore(imageStoreName);

    flyerImageFields.forEach((field) => {
      const value = String(flyer[field] || "");
      if (value) {
        store.put(value, field);
      } else {
        store.delete(field);
      }
    });

    transaction.addEventListener("complete", () => {
      db.close();
      resolve();
    });
    transaction.addEventListener("error", () => {
      db.close();
      reject(transaction.error);
    });
  });
}

export default function FlyerPage() {
  const [flyer, setFlyer] = useState(defaultFlyer);
  const [isLoaded, setIsLoaded] = useState(false);
  const [draggingRow, setDraggingRow] = useState("");
  const [previewMode, setPreviewMode] = useState("full");
  const [openEditorDropdown, setOpenEditorDropdown] = useState("");

  useEffect(() => {
    let isCancelled = false;

    async function loadFlyer() {
      let stored = {};
      let storedImages = {};

      try {
        stored = JSON.parse(window.localStorage.getItem(storageKey) || "{}");
      } catch (error) {
        console.warn("Could not load saved flyer metadata.", error);
      }

      try {
        storedImages = await loadSavedFlyerImages();
      } catch (error) {
        console.warn("Could not load saved flyer images.", error);
      }

      if (isCancelled) return;
      setFlyer(normalizeFlyer({ ...defaultFlyer, ...stored, ...storedImages }));
      setIsLoaded(true);
    }

    loadFlyer();

    return () => {
      isCancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!isLoaded) return;
    let isCancelled = false;

    saveFlyerMetadata(flyer);
    saveFlyerImages(flyer).catch((error) => {
      if (!isCancelled) console.warn("Could not save flyer images.", error);
    });

    return () => {
      isCancelled = true;
    };
  }, [flyer, isLoaded]);

  useEffect(() => {
    if (!draggingRow) return;

    function handleMove(event) {
      event.preventDefault();
      moveRowAtPoint(draggingRow, event.clientY);
    }

    function handleRelease() {
      setDraggingRow("");
    }

    window.addEventListener("pointermove", handleMove, { passive: false });
    window.addEventListener("pointerup", handleRelease);
    window.addEventListener("mousemove", handleMove);
    window.addEventListener("mouseup", handleRelease);

    return () => {
      window.removeEventListener("pointermove", handleMove);
      window.removeEventListener("pointerup", handleRelease);
      window.removeEventListener("mousemove", handleMove);
      window.removeEventListener("mouseup", handleRelease);
    };
  }, [draggingRow]);

  const flyerStyle = useMemo(
    () => ({
      "--accent-1": flyer.accentOne,
      "--accent-2": flyer.accentTwo,
      "--accent-3": flyer.accentThree,
      "--flyer-background": flyer.backgroundColor || undefined,
      "--flyer-text": flyer.textColor || undefined,
      "--flyer-outline": flyer.outlineColor || undefined,
      "--flyer-text-box": flyer.textBoxColor || undefined
    }),
    [
      flyer.accentOne,
      flyer.accentTwo,
      flyer.accentThree,
      flyer.backgroundColor,
      flyer.outlineColor,
      flyer.textBoxColor,
      flyer.textColor
    ]
  );

  const rowOrder = useMemo(() => normalizeRowOrder(flyer.rowOrder), [flyer.rowOrder]);
  const hiddenRows = useMemo(() => normalizeHiddenRows(flyer.hiddenRows), [flyer.hiddenRows]);
  const selectedColorMood = useMemo(() => getColorMood(flyer.colorMood), [flyer.colorMood]);
  const isUseOwnFlyerMode = flyer.flyerMode === flyerModes.useOwn;
  const visibleRowOrder = useMemo(
    () =>
      rowOrder.filter((rowKey) => {
        if (isUseOwnFlyerMode) {
          if (requiredRowKeys.has(rowKey)) return true;
          return rowKey === "myFlyer" && flyer.myFlyerImage;
        }
        if (rowKey === "myFlyer") return false;
        return !hiddenRows.includes(rowKey) && (rowKey !== "myFlyer" || flyer.myFlyerImage);
      }),
    [flyer.myFlyerImage, hiddenRows, isUseOwnFlyerMode, rowOrder]
  );
  const objectRowOrder = useMemo(
    () =>
      rowOrder.filter((rowKey) => {
        if (isUseOwnFlyerMode) return requiredRowKeys.has(rowKey) || (rowKey === "myFlyer" && flyer.myFlyerImage);
        return rowKey !== "myFlyer";
      }),
    [flyer.myFlyerImage, isUseOwnFlyerMode, rowOrder]
  );
  const renderedRowOrder = useMemo(() => {
    const hasBothNotes = noteRowKeys.every((rowKey) => visibleRowOrder.includes(rowKey));
    if (!hasBothNotes) return visibleRowOrder;

    let didRenderNotes = false;
    return visibleRowOrder.flatMap((rowKey) => {
      if (!noteRowKeys.includes(rowKey)) return rowKey;
      if (didRenderNotes) return [];
      didRenderNotes = true;
      return "notes";
    });
  }, [visibleRowOrder]);
  const isCorkPreview = previewMode === "cork";

  function updateField(key, value) {
    setFlyer((current) => ({ ...current, [key]: value }));
  }

  function handleEditorDropdownToggle(event, dropdownId) {
    const isOpen = event.currentTarget.open;
    setOpenEditorDropdown((current) => (isOpen ? dropdownId : current === dropdownId ? "" : current));
  }

  function setFlyerMode(mode) {
    setFlyer((current) => {
      const currentHiddenRows = normalizeHiddenRows(current.hiddenRows);

      if (mode === flyerModes.useOwn) {
        return {
          ...current,
          flyerMode: flyerModes.useOwn,
          hiddenRows: Array.from(
            new Set([
              ...currentHiddenRows.filter((rowKey) => rowKey !== "myFlyer"),
              ...generatedBodyRows
            ])
          )
        };
      }

      return {
        ...current,
        flyerMode: flyerModes.create,
        hiddenRows: Array.from(
          new Set([
            ...currentHiddenRows.filter((rowKey) => !generatedBodyRows.includes(rowKey)),
            "myFlyer"
          ])
        )
      };
    });
  }

  function toggleRowVisibility(rowKey) {
    if (requiredRowKeys.has(rowKey)) return;

    setFlyer((current) => {
      const currentHiddenRows = normalizeHiddenRows(current.hiddenRows);
      const isHidden = currentHiddenRows.includes(rowKey);
      const nextHiddenRows = isHidden
        ? currentHiddenRows.filter((key) => key !== rowKey)
        : [...currentHiddenRows, rowKey];
      return { ...current, hiddenRows: nextHiddenRows };
    });
  }

  function moveRow(rowKey, targetKey, placement) {
    if (rowKey === targetKey) return;

    setFlyer((current) => {
      const currentOrder = normalizeRowOrder(current.rowOrder);
      const movingKeys = rowKey === "notes" ? noteRowKeys : [rowKey];
      const targetKeys = targetKey === "notes" ? noteRowKeys : [targetKey];
      if (movingKeys.some((key) => targetKeys.includes(key))) return current;

      const withoutMoved = currentOrder.filter((key) => !movingKeys.includes(key));
      const targetIndexes = targetKeys.map((key) => withoutMoved.indexOf(key)).filter((index) => index !== -1);
      if (targetIndexes.length === 0) return current;

      const insertIndex =
        placement === "after" ? Math.max(...targetIndexes) + 1 : Math.min(...targetIndexes);
      const nextOrder = [...withoutMoved.slice(0, insertIndex), ...movingKeys, ...withoutMoved.slice(insertIndex)];
      return { ...current, layoutMode: "custom", rowOrder: nextOrder };
    });
  }

  function moveRowAtPoint(rowKey, clientY) {
    const rowElements = Array.from(document.querySelectorAll(".flyer-row")).filter(
      (row) => row.dataset.rowKey !== rowKey
    );
    if (rowElements.length === 0) return;

    const beforeTarget = rowElements.find((row) => {
      const rect = row.getBoundingClientRect();
      return clientY < rect.top + rect.height / 2;
    });

    if (beforeTarget?.dataset.rowKey) {
      moveRow(rowKey, beforeTarget.dataset.rowKey, "before");
      return;
    }

    const lastRow = rowElements[rowElements.length - 1];
    if (lastRow?.dataset.rowKey) moveRow(rowKey, lastRow.dataset.rowKey, "after");
  }

  function handleRowGrab(event, rowKey) {
    if (typeof event.button === "number" && event.button !== 0) return;
    event.preventDefault();
    setDraggingRow(rowKey);
  }

  function applyVibe(vibe) {
    setFlyer((current) => ({
      ...current,
      ...getFlyerCopy(vibe.key),
      vibe: vibe.key,
      accentOne: vibe.accents[0],
      accentTwo: vibe.accents[1],
      accentThree: vibe.accents[2],
      colorMood: "classic",
      communityImage: ""
    }));
  }

  function handleImageUpload(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.addEventListener("load", () => {
      updateField("communityImage", String(reader.result));
    });
    reader.readAsDataURL(file);
  }

  function handleMyFlyerUpload(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.addEventListener("load", () => {
      setFlyer((current) => ({
        ...current,
        flyerMode: flyerModes.useOwn,
        myFlyerImage: String(reader.result),
        hiddenRows: Array.from(
          new Set([
            ...normalizeHiddenRows(current.hiddenRows).filter((rowKey) => rowKey !== "myFlyer"),
            ...generatedBodyRows
          ])
        )
      }));
    });
    reader.readAsDataURL(file);
  }

  function handleAvatarUpload(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.addEventListener("load", () => {
      updateField("avatarImage", String(reader.result));
    });
    reader.readAsDataURL(file);
  }

  function removeMyFlyerImage() {
    setFlyer((current) => {
      const currentHiddenRows = normalizeHiddenRows(current.hiddenRows);
      const hiddenRows = Array.from(
        new Set([
          ...currentHiddenRows.filter((rowKey) => !generatedBodyRows.includes(rowKey)),
          "myFlyer"
        ])
      );
      return { ...current, flyerMode: flyerModes.create, myFlyerImage: "", hiddenRows };
    });
  }

  return (
    <main className={`stage${isCorkPreview ? " is-cork-preview" : ""}`}>
      <section className="editor-panel" aria-labelledby="editor-title">
        <div className="editor-heading">
          <p>Flyer Editor</p>
          <h2 id="editor-title">Community signature + flyer facts</h2>
          <small className="editor-helper">Grab rows to rearrange. Click flyer text to edit.</small>
        </div>

        <div className="flyer-mode-toggle" role="group" aria-label="Flyer creation mode">
          <button
            className={!isUseOwnFlyerMode ? "is-active" : ""}
            type="button"
            onClick={() => setFlyerMode(flyerModes.create)}
          >
            Create your own
          </button>
          <button
            className={isUseOwnFlyerMode ? "is-active" : ""}
            type="button"
            onClick={() => setFlyerMode(flyerModes.useOwn)}
          >
            Use your own flyer
          </button>
        </div>

        <details
          className="editor-section vibe-editor"
          open={openEditorDropdown === "vibe"}
          onToggle={(event) => handleEditorDropdownToggle(event, "vibe")}
        >
          <summary id="vibe-title">Flyer vibe</summary>
          <div className="editor-popover">
            <div className="vibe-grid">
              {vibes.map((vibe) => {
                const isSelected = flyer.vibe === vibe.key;
                return (
                  <div className="vibe-card" key={vibe.key}>
                    <button
                      className={`vibe-button vibe-choice-${vibe.key}${isSelected ? " is-selected" : ""}`}
                      type="button"
                      onClick={() => applyVibe(vibe)}
                    >
                      <span>{vibe.name}</span>
                      <small>{vibe.description}</small>
                      <i aria-hidden="true">
                        {vibe.accents.map((color) => (
                          <b key={color} style={{ "--dot": color }} />
                        ))}
                      </i>
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        </details>

        {!isUseOwnFlyerMode ? (
          <details
            className="editor-section object-editor"
            open={openEditorDropdown === "objects"}
            onToggle={(event) => handleEditorDropdownToggle(event, "objects")}
          >
            <summary>Objects</summary>
            <div className="editor-popover">
              <div className="object-list">
                {objectRowOrder.map((rowKey) => {
                  const isVisible = !hiddenRows.includes(rowKey);
                  const isRequired = requiredRowKeys.has(rowKey);
                  const label = getRowLabel(rowKey, flyer);
                  return (
                    <label className={`object-toggle${isRequired ? " is-required" : ""}`} key={rowKey}>
                      <input
                        checked={isVisible}
                        disabled={isRequired}
                        onChange={() => toggleRowVisibility(rowKey)}
                        type="checkbox"
                      />
                      <span>{isRequired ? `Required ${label}` : `Show/hide ${label}`}</span>
                    </label>
                  );
                })}
              </div>
            </div>
          </details>
        ) : null}

        <details
          className="editor-section palette-editor"
          open={openEditorDropdown === "palette"}
          onToggle={(event) => handleEditorDropdownToggle(event, "palette")}
        >
          <summary id="palette-title">Style</summary>
          <div className="editor-popover">
            <div className="color-control-group">
              <strong>Background</strong>
              <div className="background-swatch-row">
                {backgroundColors.map((color) => {
                  const isSelected = String(flyer.backgroundColor || "").toLowerCase() === color.value;
                  return (
                    <button
                      className={`swatch-button${isSelected ? " is-selected" : ""}`}
                      key={color.value}
                      type="button"
                      title={color.name}
                      aria-label={`Background: ${color.name}`}
                      style={{ "--swatch": color.value }}
                      onClick={() => updateField("backgroundColor", color.value)}
                    />
                  );
                })}
              </div>
              {flyer.backgroundColor ? (
                <button className="inline-reset-button" type="button" onClick={() => updateField("backgroundColor", "")}>
                  Reset to vibe
                </button>
              ) : null}
            </div>

            <div className="color-control-group">
              <strong>Text</strong>
              <div className="background-swatch-row">
                {inkColors.map((color) => {
                  const isSelected = String(flyer.textColor || "").toLowerCase() === color.value;
                  return (
                    <button
                      className={`swatch-button${isSelected ? " is-selected" : ""}`}
                      key={`text-${color.value}`}
                      type="button"
                      title={color.name}
                      aria-label={`Text: ${color.name}`}
                      style={{ "--swatch": color.value }}
                      onClick={() => updateField("textColor", color.value)}
                    />
                  );
                })}
              </div>
              {flyer.textColor ? (
                <button className="inline-reset-button" type="button" onClick={() => updateField("textColor", "")}>
                  Reset to vibe
                </button>
              ) : null}
            </div>

            <div className="color-control-group">
              <strong>Outlines</strong>
              <div className="background-swatch-row">
                {inkColors.map((color) => {
                  const isSelected = String(flyer.outlineColor || "").toLowerCase() === color.value;
                  return (
                    <button
                      className={`swatch-button${isSelected ? " is-selected" : ""}`}
                      key={`outline-${color.value}`}
                      type="button"
                      title={color.name}
                      aria-label={`Outlines: ${color.name}`}
                      style={{ "--swatch": color.value }}
                      onClick={() => updateField("outlineColor", color.value)}
                    />
                  );
                })}
              </div>
              {flyer.outlineColor ? (
                <button className="inline-reset-button" type="button" onClick={() => updateField("outlineColor", "")}>
                  Reset to vibe
                </button>
              ) : null}
            </div>

            <div className="color-control-group">
              <strong>Text Boxes</strong>
              <div className="background-swatch-row">
                {backgroundColors.map((color) => {
                  const isSelected = String(flyer.textBoxColor || "").toLowerCase() === color.value;
                  return (
                    <button
                      className={`swatch-button${isSelected ? " is-selected" : ""}`}
                      key={`textbox-${color.value}`}
                      type="button"
                      title={color.name}
                      aria-label={`Text boxes: ${color.name}`}
                      style={{ "--swatch": color.value }}
                      onClick={() => updateField("textBoxColor", color.value)}
                    />
                  );
                })}
              </div>
              {flyer.textBoxColor ? (
                <button className="inline-reset-button" type="button" onClick={() => updateField("textBoxColor", "")}>
                  Reset to vibe
                </button>
              ) : null}
            </div>

            <div className="color-control-group">
              <strong>Depth</strong>
              <div className="depth-control" role="group" aria-label="Depth">
                {depthOptions.map((option) => (
                  <button
                    className={flyer.depth === option.id ? "is-active" : ""}
                    key={option.id}
                    type="button"
                    title={option.description}
                    onClick={() => updateField("depth", option.id)}
                  >
                    {option.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </details>

        <details
          className="editor-section"
          open={openEditorDropdown === "image"}
          onToggle={(event) => handleEditorDropdownToggle(event, "image")}
        >
          <summary>Image</summary>
          <div className="editor-popover">
            <label>
              Profile image
              <input type="file" accept="image/*" onChange={handleAvatarUpload} />
            </label>
            {flyer.avatarImage ? (
              <button className="inline-reset-button" type="button" onClick={() => updateField("avatarImage", "")}>
                Remove profile image
              </button>
            ) : null}
            <label>
              Community image
              <input type="file" accept="image/*" onChange={handleImageUpload} />
            </label>
            <label>
              My flyer image
              <input type="file" accept="image/*" onChange={handleMyFlyerUpload} />
            </label>
            {flyer.myFlyerImage ? (
              <button className="inline-reset-button" type="button" onClick={removeMyFlyerImage}>
                Remove my flyer image
              </button>
            ) : null}
          </div>
        </details>

        <button className="reset-button" type="button" onClick={() => setFlyer(defaultFlyer)}>
          Reset example
        </button>
      </section>

      <div className={`flyer-preview-shell${isCorkPreview ? " is-cork-preview" : ""}`}>
        <div className="preview-mode-toggle" role="group" aria-label="Preview size">
          <button
            className={previewMode === "full" ? "is-active" : ""}
            type="button"
            onClick={() => setPreviewMode("full")}
          >
            Full flyer
          </button>
          <button
            className={previewMode === "cork" ? "is-active" : ""}
            type="button"
            onClick={() => setPreviewMode("cork")}
          >
            Cork preview
          </button>
        </div>
        <div className="flyer-preview-inner">
          <article
            className={`community-flyer${isCorkPreview ? "" : " is-editing"}${flyer.backgroundColor ? " has-custom-background" : ""}${flyer.textColor ? " has-custom-text" : ""}${flyer.outlineColor ? " has-custom-outline" : ""}${flyer.textBoxColor ? " has-custom-text-boxes" : ""} depth-${flyer.depth || "soft"} color-mood-${selectedColorMood.id} vibe-${flyer.vibe || "70s-community"}`}
            style={flyerStyle}
            aria-labelledby="flyer-title"
          >
            <div
              className={`flyer-rows visible-count-${renderedRowOrder.length}${
                visibleRowOrder.length === 1 && visibleRowOrder[0] === "art" ? " is-image-only" : ""
              }`}
            >
              {renderedRowOrder.map((rowKey, index) => (
                <FlyerRow
                  canRearrange={!isCorkPreview}
                  index={index}
                  isDragging={draggingRow === rowKey}
                  key={rowKey}
                  label={getRowLabel(rowKey, flyer)}
                  onGrab={(event) => handleRowGrab(event, rowKey)}
                  rowKey={rowKey}
                >
                  {rowKey === "header" ? (
                    <FlyerHeader flyer={flyer} isEditable={!isCorkPreview} updateField={updateField} />
                  ) : null}
                  {rowKey === "signature" ? (
                    <SignatureRow flyer={flyer} isEditable={!isCorkPreview} updateField={updateField} />
                  ) : null}
                  {rowKey === "myFlyer" ? <MyFlyerRow flyer={flyer} /> : null}
                  {rowKey === "title" ? (
                    <EditableText
                      as="h1"
                      className={`flyer-title ${getTitleFitClass(flyer.title)}`}
                      editable={!isCorkPreview}
                      id="flyer-title"
                      label="Flyer title"
                      onCommit={(value) => updateField("title", value)}
                      singleLine
                      value={flyer.title}
                    />
                  ) : null}
                  {rowKey === "whenWhere" ? (
                    <WhenWhereRow flyer={flyer} isEditable={!isCorkPreview} updateField={updateField} />
                  ) : null}
                  {rowKey === "art" ? (
                    <PosterArt flyer={flyer} isEditable={!isCorkPreview} updateField={updateField} />
                  ) : null}
                  {rowKey === "notes" ? (
                    <NotesRow flyer={flyer} isEditable={!isCorkPreview} updateField={updateField} />
                  ) : null}
                  {rowKey === "whatWeDo" ? (
                    <CopyCardRow
                      bodyKey="whatWeDo"
                      bodyLabel="What we do"
                      headingKey="whatWeDoLabel"
                      headingLabel="What we do heading"
                      flyer={flyer}
                      isEditable={!isCorkPreview}
                      updateField={updateField}
                    />
                  ) : null}
                  {rowKey === "firstTimerNote" ? (
                    <CopyCardRow
                      bodyKey="firstTimerNote"
                      bodyLabel="First-timer note"
                      headingKey="firstTimerNoteLabel"
                      headingLabel="First-timer note heading"
                      flyer={flyer}
                      isEditable={!isCorkPreview}
                      updateField={updateField}
                    />
                  ) : null}
                </FlyerRow>
              ))}
            </div>
          </article>
        </div>
        <p className="preview-caption">{isCorkPreview ? "Cork board scale" : "Full flyer scale"}</p>
      </div>
    </main>
  );
}

function FlyerRow({
  canRearrange = true,
  children,
  index,
  isDragging,
  label,
  onGrab,
  rowKey
}) {
  return (
    <section
      className={`flyer-row flyer-row-${rowKey}${isDragging ? " is-dragging" : ""}`}
      data-row-key={rowKey}
      style={{ "--row-index": index }}
    >
      {canRearrange ? (
        <button
          aria-label={`Move ${label}`}
          className="row-grip"
          onPointerDown={onGrab}
          title={`Move ${label}`}
          type="button"
        >
          <span />
          <span />
          <span />
        </button>
      ) : null}
      {children}
    </section>
  );
}

function FlyerHeader({ flyer, isEditable = true, updateField }) {
  const selectedCategory = getCategory(flyer.category);

  return (
    <header className="flyer-header-row" aria-label="Flyer category and posted date">
      <div className="flyer-header-rule" aria-hidden="true" />
      <label className="flyer-category-control">
        <span className="flyer-category-icon-frame" aria-hidden="true">
          <img className="flyer-category-icon" src={selectedCategory.icon} alt="" />
        </span>
        <span className="visually-hidden">Flyer category</span>
        {isEditable ? (
          <select
            aria-label="Flyer category"
            className="flyer-category-select"
            value={selectedCategory.id}
            onChange={(event) => updateField("category", event.target.value)}
          >
            {categoryOptions.map((category) => (
              <option key={category.id} value={category.id}>
                {category.displayLabel}
              </option>
            ))}
          </select>
        ) : (
          <span className="flyer-category-select" aria-label="Flyer category">
            {selectedCategory.displayLabel}
          </span>
        )}
      </label>
      <span className="posted-age">{formatPostedDays(flyer.postedDaysAgo)}</span>
    </header>
  );
}

function SignatureRow({ flyer, isEditable = true, updateField }) {
  return (
    <section className="signature" aria-label="Community signature">
      <div className={`community-mark${flyer.avatarImage ? " has-avatar" : ""}`} aria-hidden="true">
        {flyer.avatarImage ? <img className="community-avatar-image" src={flyer.avatarImage} alt="" /> : null}
      </div>
      <div>
        <div className="signature-meta">
          <SignaturePhraseInput
            isEditable={isEditable}
            value={flyer.signaturePrefix}
            onChange={(value) => updateField("signaturePrefix", value)}
          />
        </div>
        <EditableText
          as="strong"
          className="community-name"
          editable={isEditable}
          label="Community name"
          onCommit={(value) => updateField("communityName", value)}
          singleLine
          value={flyer.communityName}
        />
        <EditableText
          as="p"
          className="community-line"
          editable={isEditable}
          label="Community identity"
          onCommit={(value) => updateField("communityLine", value)}
          value={flyer.communityLine}
        />
      </div>
    </section>
  );
}

function SignaturePhraseInput({ isEditable = true, onChange, value }) {
  const [isCustomOpen, setIsCustomOpen] = useState(!signatureOptions.includes(value));
  const selectValue = isCustomOpen ? "__custom__" : value;

  useEffect(() => {
    if (signatureOptions.includes(value)) setIsCustomOpen(false);
  }, [value]);

  if (!isEditable) {
    return <span className="signature-prefix">{value}</span>;
  }

  return (
    <label className="signature-prefix-control">
      <span className="visually-hidden">Signature phrase</span>
      <select
        aria-label="Signature phrase"
        className="signature-prefix signature-prefix-select"
        value={selectValue}
        onChange={(event) => {
          if (event.target.value === "__custom__") {
            setIsCustomOpen(true);
            return;
          }
          setIsCustomOpen(false);
          onChange(event.target.value);
        }}
      >
        {signatureOptions.map((option) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
        <option value="__custom__">Write your own...</option>
      </select>
      {isCustomOpen ? (
        <input
          aria-label="Custom signature phrase"
          className="signature-prefix-custom"
          maxLength={28}
          onChange={(event) => onChange(event.target.value)}
          placeholder="Pen your own"
          value={value}
        />
      ) : null}
    </label>
  );
}

function WhenWhereRow({ flyer, isEditable = true, updateField }) {
  return (
    <section className="when-where-row" aria-label="When and where">
      <div className="when-where-item">
        <strong>When / Where</strong>
        <EditableText
          as="p"
          editable={isEditable}
          label="When / Where"
          onCommit={(value) => updateField("whenWhereLine", value)}
          singleLine
          value={flyer.whenWhereLine}
        />
      </div>
    </section>
  );
}

function PosterArt({ flyer, isEditable = true, updateField }) {
  const example = vibeExamples[flyer.vibe] || vibeExamples["70s-community"];
  const imageSrc = flyer.communityImage || example.defaultImage || "/vintage-camera-default.jpg";
  const imageAlt = flyer.communityImage ? "Uploaded community flyer image" : example.imageAlt;

  function handlePhotoFallback(event) {
    if (event.currentTarget.dataset.fallbackApplied === "true") return;
    event.currentTarget.dataset.fallbackApplied = "true";
    event.currentTarget.src = "/vintage-camera-default.jpg";
  }

  return (
    <figure className="poster-art has-image">
      <img className="poster-photo" src={imageSrc} alt={imageAlt} onError={handlePhotoFallback} />
      <EditableText
        as="span"
        className="ribbon"
        editable={isEditable}
        label="Main invitation"
        onCommit={(value) => updateField("mainInvitation", value)}
        singleLine
        value={flyer.mainInvitation}
      />
    </figure>
  );
}

function MyFlyerRow({ flyer }) {
  if (!flyer.myFlyerImage) return null;

  return (
    <figure className="my-flyer-viewport" aria-label="Uploaded flyer image">
      <img className="my-flyer-image" src={flyer.myFlyerImage} alt="Uploaded flyer" />
    </figure>
  );
}

function NotesRow({ flyer, isEditable = true, updateField }) {
  return (
    <section className="community-copy">
      <CopyCard
        bodyKey="whatWeDo"
        bodyLabel="What we do"
        headingKey="whatWeDoLabel"
        headingLabel="What we do heading"
        flyer={flyer}
        isEditable={isEditable}
        updateField={updateField}
      />
      <CopyCard
        bodyKey="firstTimerNote"
        bodyLabel="First-timer note"
        headingKey="firstTimerNoteLabel"
        headingLabel="First-timer note heading"
        flyer={flyer}
        isEditable={isEditable}
        updateField={updateField}
      />
    </section>
  );
}

function CopyCardRow({ bodyKey, bodyLabel, flyer, headingKey, headingLabel, isEditable = true, updateField }) {
  return (
    <section className="community-copy community-copy-single">
      <CopyCard
        bodyKey={bodyKey}
        bodyLabel={bodyLabel}
        headingKey={headingKey}
        headingLabel={headingLabel}
        flyer={flyer}
        isEditable={isEditable}
        updateField={updateField}
      />
    </section>
  );
}

function CopyCard({ bodyKey, bodyLabel, flyer, headingKey, headingLabel, isEditable = true, updateField }) {
  return (
    <article className="copy-card">
      <EditableText
        as="strong"
        editable={isEditable}
        label={headingLabel}
        onCommit={(value) => updateField(headingKey, value)}
        singleLine
        value={flyer[headingKey]}
      />
      <EditableText
        as="p"
        editable={isEditable}
        label={bodyLabel}
        onCommit={(value) => updateField(bodyKey, value)}
        value={flyer[bodyKey]}
      />
    </article>
  );
}

function EditableText({ as: Tag, className = "", editable = true, id, label, onCommit, singleLine = false, value }) {
  function commitText(event) {
    const nextValue = event.currentTarget.innerText.replace(/\u00a0/g, " ").trim();
    if (nextValue && nextValue !== value) onCommit(nextValue);
    if (!nextValue) event.currentTarget.innerText = value;
  }

  function handleKeyDown(event) {
    if (singleLine && event.key === "Enter") {
      event.preventDefault();
      event.currentTarget.blur();
    }
  }

  function handlePaste(event) {
    event.preventDefault();
    const text = event.clipboardData.getData("text/plain");
    document.execCommand("insertText", false, singleLine ? text.replace(/\s+/g, " ") : text);
  }

  return (
    <Tag
      aria-label={editable ? `${label}. Click to edit.` : label}
      className={`editable-text ${className}`}
      contentEditable={editable}
      id={id}
      onBlur={editable ? commitText : undefined}
      onKeyDown={editable ? handleKeyDown : undefined}
      onPaste={editable ? handlePaste : undefined}
      role={editable ? "textbox" : undefined}
      suppressContentEditableWarning
      tabIndex={editable ? 0 : undefined}
    >
      {value}
    </Tag>
  );
}
