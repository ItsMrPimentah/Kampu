import { FORMAT_CONFIG, formatConfig, type FootballFormat } from '../teams/formats';

export interface ChallengeFormat {
  format: FootballFormat;
  startingRoster: number;
  requiresTeamReadiness: true;
  policyVersion: 'formats-v1';
}

export function validateChallengeFormat(input: string): ChallengeFormat {
  const config = formatConfig(input);
  return {
    format: input as FootballFormat,
    startingRoster: config.startingRoster,
    requiresTeamReadiness: true,
    policyVersion: 'formats-v1',
  };
}

export function supportedChallengeFormats(): ChallengeFormat[] {
  return Object.keys(FORMAT_CONFIG).map(validateChallengeFormat);
}
