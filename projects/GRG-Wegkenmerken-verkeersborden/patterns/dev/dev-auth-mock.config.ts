import { AuthRoleEnum } from '@core/auth/auth.roles';
import { Organization } from '@modules/user/models';
import { RoadAuthorityType } from '@shared/enums';

export const DEV_MOCK_ENABLED_KEY = 'dev-mock-enabled';
export const DEV_MOCK_PERSONA_KEY = 'dev-mock-persona';

export interface DevPersona {
  label: string;
  roles: AuthRoleEnum[];
  organization: Organization;
}

export const DEV_PERSONAS: Record<string, DevPersona> = {
  denBoschUser: {
    label: 'Den Bosch — gemeente gebruiker',
    roles: [AuthRoleEnum.User, AuthRoleEnum.TrafficSignEdit, AuthRoleEnum.RoadFeatureEdit],
    organization: {
      id: 'mock-org-den-bosch',
      name: 'Gemeente Den Bosch (MOCK)',
      hasGlobalMutationPermissions: false,
      hasRvmMutationPermissions: false,
      hasHgvChargePermissions: false,
      roadAuthorities: [
        {
          id: 'mock-ra-den-bosch',
          name: 'Den Bosch',
          type: RoadAuthorityType.G,
          code: '796',
          rwsId: '',
        },
      ],
    },
  },
  adminUser: {
    label: 'NDW Admin',
    roles: [AuthRoleEnum.User, AuthRoleEnum.Admin, AuthRoleEnum.TrafficSignEdit, AuthRoleEnum.RoadFeatureEdit],
    organization: {
      id: 'mock-org-admin',
      name: 'NDW Admin Org (MOCK)',
      hasGlobalMutationPermissions: true,
      hasRvmMutationPermissions: true,
      hasHgvChargePermissions: true,
      roadAuthorities: [],
    },
  },
};

const DEFAULT_PERSONA_KEY = 'denBoschUser';

const storedEnabled = localStorage.getItem(DEV_MOCK_ENABLED_KEY);
export const DEV_AUTH_MOCK_ENABLED: boolean = storedEnabled === null ? true : storedEnabled === 'true';

const storedPersonaKey = localStorage.getItem(DEV_MOCK_PERSONA_KEY) ?? DEFAULT_PERSONA_KEY;
const resolvedKey = storedPersonaKey in DEV_PERSONAS ? storedPersonaKey : DEFAULT_PERSONA_KEY;
export const DEV_ACTIVE_PERSONA: DevPersona = DEV_PERSONAS[resolvedKey];
export const DEV_ACTIVE_PERSONA_KEY: string = resolvedKey;
