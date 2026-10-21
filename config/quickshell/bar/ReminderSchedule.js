// Calendar intervals retain the original local time and day where possible.
function normalizeRepeat(repeat) {
  if (!repeat || ["hour", "day", "week", "month", "year"].indexOf(repeat.unit) < 0)
    return null
  const every = Number(repeat.every)
  if (!Number.isInteger(every) || every < 1 || every > 999) return null
  const value = { every: every, unit: repeat.unit }
  if (typeof repeat.until === "number" && Number.isFinite(repeat.until))
    value.until = repeat.until
  if (Number.isInteger(repeat.count) && repeat.count >= 1 && repeat.count <= 9999)
    value.count = repeat.count
  return value
}

function occurrence(anchor, repeat, index) {
  const date = new Date(anchor)
  const amount = repeat.every * index
  if (repeat.unit === "hour") return anchor + amount * 3600000
  if (repeat.unit === "day" || repeat.unit === "week") {
    date.setDate(date.getDate() + amount * (repeat.unit === "week" ? 7 : 1))
  } else {
    const day = date.getDate()
    date.setDate(1)
    if (repeat.unit === "month") date.setMonth(date.getMonth() + amount)
    else date.setFullYear(date.getFullYear() + amount)
    const lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
    date.setDate(Math.min(day, lastDay))
  }
  return date.getTime()
}

function nextDue(reminder, now) {
  const repeat = normalizeRepeat(reminder.repeat)
  if (!repeat) return null
  const anchor = Number.isFinite(reminder.repeatAnchor) ? reminder.repeatAnchor : reminder.due
  const start = new Date(anchor)
  const end = new Date(now)
  let estimate
  if (repeat.unit === "month")
    estimate = ((end.getFullYear() - start.getFullYear()) * 12 + end.getMonth() - start.getMonth()) / repeat.every
  else if (repeat.unit === "year")
    estimate = (end.getFullYear() - start.getFullYear()) / repeat.every
  else
    estimate = (now - anchor) / (repeat.every * (repeat.unit === "hour" ? 3600000 : repeat.unit === "week" ? 604800000 : 86400000))
  let index = Math.max(1, Math.floor(estimate))
  while (index > 1 && occurrence(anchor, repeat, index - 1) > now) index--
  let next = occurrence(anchor, repeat, index)
  while (next <= now) next = occurrence(anchor, repeat, ++index)
  if (repeat.count && index >= repeat.count) return null
  if (repeat.until !== undefined && next > repeat.until) return null
  return Number.isFinite(next) ? next : null
}

function repeatLabel(repeat) {
  const value = normalizeRepeat(repeat)
  const label = value ? "Every " + (value.every === 1 ? "" : value.every + " ")
    + value.unit + (value.every === 1 ? "" : "s") : "Does not repeat"
  if (!value) return label
  if (value.count) return label + " · " + value.count + " occurrences total"
  if (value.until !== undefined) {
    const end = new Date(value.until)
    return label + " · until " + end.getFullYear() + "-"
      + String(end.getMonth() + 1).padStart(2, "0") + "-" + String(end.getDate()).padStart(2, "0")
  }
  return label + " · no end"
}

function validLimits(repeat, due, anchor) {
  const value = normalizeRepeat(repeat)
  if (!value) return !repeat
  if (value.until !== undefined && value.until < due) return false
  if (value.count && occurrence(anchor, value, value.count - 1) < due) return false
  return true
}

function parseDate(text) {
  const parts = text.match(/^(\d{4})-(\d{2})-(\d{2})$/)
  if (!parts) return null
  const date = new Date(Number(parts[1]), Number(parts[2]) - 1, Number(parts[3]))
  return date.getFullYear() === Number(parts[1]) && date.getMonth() === Number(parts[2]) - 1
    && date.getDate() === Number(parts[3]) ? date : null
}
