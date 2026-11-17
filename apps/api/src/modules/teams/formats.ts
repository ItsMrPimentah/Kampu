export const FORMAT_CONFIG = {
  '5v5': { label: '5v5', startingRoster: 5 },
  '7v7': { label: '7v7', startingRoster: 7 },
  '11v11': { label: '11v11', startingRoster: 11 },
  futsal: { label: 'Futsal', startingRoster: 5 },
  futevoley_2v2: { label: 'Futevoley 2v2', startingRoster: 2 },
} as const;

export type FootballFormat = keyof typeof FORMAT_CONFIG;

export interface RosterReadiness {
  format: FootballFormat;
  supported: boolean;
  requiredPlayers: number;
  eligiblePlayers: number;
  ready: boolean;
  additionalPlayersNeeded: number;
}

export function formatConfig(value: string): (typeof FORMAT_CONFIG)[FootballFormat] {
  if (!(value in FORMAT_CONFIG)) throw new Error(`Unsupported football format: ${value}`);
  return FORMAT_CONFIG[value as FootballFormat];
}

export function calculateReadiness(format: string, supportedFormats: string[], eligibleStartingPlayers: number): RosterReadiness {
  const config = formatConfig(format);
  const supported = supportedFormats.includes(format);
  const eligiblePlayers = Math.max(0, Math.floor(eligibleStartingPlayers));
  return {
    format: format as FootballFormat,
    supported,
    requiredPlayers: config.startingRoster,
    eligiblePlayers,
    ready: supported && eligiblePlayers >= config.startingRoster,
    additionalPlayersNeeded: supported ? Math.max(0, config.startingRoster - eligiblePlayers) : config.startingRoster,
  };
}
