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
    label: 'Den Bosch regio — gemeente gebruiker',
    roles: [AuthRoleEnum.User, AuthRoleEnum.TrafficSignEdit, AuthRoleEnum.RoadFeatureEdit],
    organization: {
      id: 'mock-org-den-bosch',
      name: 'Gemeente Den Bosch (MOCK)',
      hasGlobalMutationPermissions: false,
      hasRvmMutationPermissions: false,
      hasHgvChargePermissions: false,
      roadAuthorities: [
        {
          id: '53f8c8c3-1cf7-473e-9772-fa7156b0acc8',
          name: "Gemeente 's-Hertogenbosch",
          type: RoadAuthorityType.G,
          code: '796',
          rwsId: '2009',
        },
        {
          id: 'c1311f69-e931-4650-b3db-6b5dd028ee67',
          name: 'Gemeente Heusden',
          type: RoadAuthorityType.G,
          code: '797',
          rwsId: '2013',
        },
        {
          id: '2c827d41-c2ab-4d30-bbf6-dc39cdeea029',
          name: 'Gemeente Vught',
          type: RoadAuthorityType.G,
          code: '865',
          rwsId: '2022',
        },
        {
          id: '1df3d013-291e-4091-bd35-bd8b65741562',
          name: 'Gemeente Sint-Michielsgestel',
          type: RoadAuthorityType.G,
          code: '845',
          rwsId: '2021',
        },
      ],
    },
  },
  utrechtUser: {
    label: 'Utrecht regio — gemeente gebruiker',
    roles: [AuthRoleEnum.User, AuthRoleEnum.TrafficSignEdit, AuthRoleEnum.RoadFeatureEdit],
    organization: {
      id: 'mock-org-utrecht',
      name: 'Gemeente Utrecht (MOCK)',
      hasGlobalMutationPermissions: false,
      hasRvmMutationPermissions: false,
      hasHgvChargePermissions: false,
      roadAuthorities: [
        {
          id: '337d9d4d-d569-4897-88f1-0dee1b82aee2',
          name: 'Gemeente Utrecht',
          type: RoadAuthorityType.G,
          code: '344',
          rwsId: '1849',
        },
        {
          id: '39716880-5002-4887-93e6-854c53b35fd1',
          name: 'Gemeente De Bilt',
          type: RoadAuthorityType.G,
          code: '310',
          rwsId: '1826',
        },
        {
          id: 'd0715570-a37b-431c-8be1-79c29afab83f',
          name: 'Gemeente Zeist',
          type: RoadAuthorityType.G,
          code: '355',
          rwsId: '1835',
        },
        {
          id: 'ac33c1a2-5081-4c08-b091-edd420ffa19f',
          name: 'Gemeente Nieuwegein',
          type: RoadAuthorityType.G,
          code: '356',
          rwsId: '1879',
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
