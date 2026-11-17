import type { AppConfig } from '../config/env';

export type FeatureFlag = 'nativeBooking' | 'payments' | 'advertising';

export class FeatureFlags {
  constructor(private readonly config: Pick<AppConfig, 'featureFlags'>) {}

  enabled(flag: FeatureFlag): boolean {
    return this.config.featureFlags[flag] === true;
  }

  snapshot(): Record<FeatureFlag, boolean> {
    return {
      nativeBooking: this.enabled('nativeBooking'),
      payments: this.enabled('payments'),
      advertising: this.enabled('advertising'),
    };
  }
}
