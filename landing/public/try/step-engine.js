const RULES = [
  {
    match: /\b(reply|respond|email|message|text|dm)\b/i,
    steps: [
      "Open the conversation and read the last message.",
      "Write a one-sentence reply without sending it yet.",
      "Type just the greeting and the person's name."
    ]
  },
  {
    match: /\b(call|phone|ring)\b/i,
    steps: [
      "Find the number and put it on your screen.",
      "Write down the first sentence you want to say.",
      "Open the dialer and enter the number."
    ]
  },
  {
    match: /\b(write|essay|report|proposal|article|draft|document)\b/i,
    steps: [
      "Open a blank document and write a rough title.",
      "Write one deliberately messy opening sentence.",
      "List three words the document needs to cover."
    ]
  },
  {
    match: /\b(read|study|revise|chapter|paper)\b/i,
    steps: [
      "Open the material to the first unread page.",
      "Read only the first paragraph.",
      "Put the material in front of you and find your place."
    ]
  },
  {
    match: /\b(clean|tidy|declutter|room|desk|kitchen)\b/i,
    steps: [
      "Pick up one visible item and put it where it belongs.",
      "Clear one hand-sized patch of space.",
      "Bring an empty bag or basket into the room."
    ]
  },
  {
    match: /\b(laundry|wash clothes|washing)\b/i,
    steps: [
      "Put one piece of clothing into the laundry basket.",
      "Bring the laundry basket next to the machine.",
      "Separate out just the first load."
    ]
  },
  {
    match: /\b(dish|dishes|washing up)\b/i,
    steps: [
      "Put one dish beside the sink.",
      "Turn on the water and wash one cup.",
      "Gather the dishes from one surface."
    ]
  },
  {
    match: /\b(pay|bill|invoice|tax|bank)\b/i,
    steps: [
      "Open the bill or payment page.",
      "Find the amount and due date—nothing else yet.",
      "Put your payment details within reach."
    ]
  },
  {
    match: /\b(book|appointment|reserve|schedule)\b/i,
    steps: [
      "Find the booking page or phone number.",
      "Open your calendar to a week that could work.",
      "Write down two times you could accept."
    ]
  },
  {
    match: /\b(form|application|apply|paperwork)\b/i,
    steps: [
      "Open the form and read only the first question.",
      "Put the first required document beside you.",
      "Fill in just your name."
    ]
  },
  {
    match: /\b(pack|packing|suitcase|bag)\b/i,
    steps: [
      "Put the empty bag where you can reach it.",
      "Place one essential item beside the bag.",
      "Write a list of just three essentials."
    ]
  },
  {
    match: /\b(exercise|workout|run|walk|gym|yoga)\b/i,
    steps: [
      "Put on the first piece of clothing you would exercise in.",
      "Put your shoes beside the door.",
      "Stand up and take one slow stretch."
    ]
  }
];

const FALLBACKS = [
  "Put the task in front of you: open the app, page, or object you'll need.",
  "Name the smallest visible part of this task, then touch or open it.",
  "Set out one thing you will need. You can stop there."
];

export function normalizeTask(task) {
  return String(task ?? "").trim().replace(/\s+/g, " ");
}

export function suggestFirstStep(task, attempt = 0) {
  const normalizedTask = normalizeTask(task);
  if (!normalizedTask) {
    return "Type the thing you're avoiding, in any words that come to mind.";
  }

  const rule = RULES.find((candidate) => candidate.match.test(normalizedTask));
  const choices = rule?.steps ?? FALLBACKS;
  const safeAttempt = Number.isFinite(attempt) ? Math.max(0, Math.floor(attempt)) : 0;
  return choices[safeAttempt % choices.length];
}

export const stepRuleCount = RULES.length;
