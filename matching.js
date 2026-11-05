export function findMatches(source, posts, limit = 20) {
  const active = p => p.type === '交換' && p.status === '交換中';
  if (!active(source)) return { pairs: [], cycles: [] };
  const fits = (giver, receiver) =>
    giver.benefit === receiver.wanted_benefit &&
    (receiver.wanted_band === '任一團體' || giver.band === receiver.wanted_band) &&
    giver.days.some(day => receiver.wanted_day === '兩天皆可' || day === receiver.wanted_day);
  const distinct = (a, b) => a.id !== b.id &&
    (!a.contact || !b.contact || a.contact.trim().replace(/\/$/, '') !== b.contact.trim().replace(/\/$/, ''));
  const candidates = posts.filter(p => active(p) && distinct(source, p));
  const outgoing = candidates.filter(p => fits(source, p));
  const incoming = candidates.filter(p => fits(p, source));
  const pairs = outgoing.filter(p => fits(p, source)).slice(0, limit).map(p => [source, p]);
  const cycles = [];
  for (const b of outgoing) {
    for (const c of incoming) {
      if (distinct(b, c) && fits(b, c)) cycles.push([source, b, c]);
      if (cycles.length === limit) return { pairs, cycles };
    }
  }
  return { pairs, cycles };
}
