import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RoadAuthority } from '@modules/road-feature/models';
import { UserRepository } from '@modules/user/state/user.repository';
import { environment } from '@env/environment';
import {
  DEV_ACTIVE_PERSONA_KEY,
  DEV_AUTH_MOCK_ENABLED,
  DEV_MOCK_ENABLED_KEY,
  DEV_MOCK_PERSONA_KEY,
  DEV_PERSONAS,
} from './dev-auth-mock.config';

@Component({
  selector: 'tsf-dev-auth-panel',
  templateUrl: './dev-auth-panel.component.html',
  styleUrl: './dev-auth-panel.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DevAuthPanelComponent {
  readonly #userRepository = inject(UserRepository);

  readonly isVisible = environment.environmentType !== 'production';
  readonly isExpanded = signal(false);
  readonly activePersonaKey = signal(DEV_ACTIVE_PERSONA_KEY);
  readonly mockEnabled = signal(DEV_AUTH_MOCK_ENABLED);

  readonly personaKeys = Object.keys(DEV_PERSONAS);
  readonly personas = DEV_PERSONAS;

  readonly organization = this.#userRepository.organization;
  readonly activeRoadAuthority = this.#userRepository.activeRoadAuthority;

  readonly roadAuthorities = computed(() => this.organization()?.roadAuthorities ?? []);
  readonly pillLabel = computed(() => {
    const label = this.personas[this.activePersonaKey()]?.label ?? this.activePersonaKey();
    return this.mockEnabled() ? label : `${label} (uitgeschakeld)`;
  });

  toggle(): void {
    this.isExpanded.update((v) => !v);
  }

  selectPersona(key: string): void {
    if (key === this.activePersonaKey()) return;
    localStorage.setItem(DEV_MOCK_PERSONA_KEY, key);
    window.location.reload();
  }

  toggleMock(): void {
    localStorage.setItem(DEV_MOCK_ENABLED_KEY, String(!this.mockEnabled()));
    window.location.reload();
  }

  selectRoadAuthority(roadAuthority: RoadAuthority): void {
    this.#userRepository.updateActiveRoadAuthority(roadAuthority);
  }
}
