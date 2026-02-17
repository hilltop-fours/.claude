import { Project, ClassDeclaration, PropertyDeclaration, MethodDeclaration, GetAccessorDeclaration, SetAccessorDeclaration, ConstructorDeclaration, SyntaxKind, Node } from 'ts-morph';
import * as path from 'path';

const LIFECYCLE_HOOKS = new Set([
  'ngOnInit', 'ngOnDestroy', 'ngAfterViewInit', 'ngAfterContentInit',
  'ngOnChanges', 'ngDoCheck', 'ngAfterContentChecked', 'ngAfterViewChecked',
]);

// Main categories in expected order
enum Category {
  INJECT = 1,
  STATIC = 2,
  PUBLIC_FIELD = 3,
  PROTECTED_FIELD = 4,
  PRIVATE_FIELD = 5,
  CONSTRUCTOR = 6,
  LIFECYCLE = 7,
  GETTER_SETTER = 8,
  PUBLIC_METHOD = 9,
  PROTECTED_METHOD = 10,
  PRIVATE_METHOD = 11,
}

// Sub-categories for fields (signal ordering)
enum FieldSubCategory {
  READONLY_CONSTANT = 1,
  VIEWCHILD = 2,
  INPUT = 3,
  OUTPUT = 4,
  COMPUTED = 5,
  SIGNAL = 6,
  VARIABLE = 7,
}

const CATEGORY_LABELS: Record<Category, string> = {
  [Category.INJECT]: 'Injected dependency',
  [Category.STATIC]: 'Static field',
  [Category.PUBLIC_FIELD]: 'Public field',
  [Category.PROTECTED_FIELD]: 'Protected field',
  [Category.PRIVATE_FIELD]: 'Private field',
  [Category.CONSTRUCTOR]: 'Constructor',
  [Category.LIFECYCLE]: 'Lifecycle hook',
  [Category.GETTER_SETTER]: 'Getter/setter',
  [Category.PUBLIC_METHOD]: 'Public method',
  [Category.PROTECTED_METHOD]: 'Protected method',
  [Category.PRIVATE_METHOD]: 'Private method',
};

const SUBCATEGORY_LABELS: Record<FieldSubCategory, string> = {
  [FieldSubCategory.READONLY_CONSTANT]: 'readonly constant',
  [FieldSubCategory.VIEWCHILD]: 'viewChild/contentChild',
  [FieldSubCategory.INPUT]: 'input()',
  [FieldSubCategory.OUTPUT]: 'output()',
  [FieldSubCategory.COMPUTED]: 'computed()',
  [FieldSubCategory.SIGNAL]: 'signal()',
  [FieldSubCategory.VARIABLE]: 'variable',
};

interface ClassifiedMember {
  name: string;
  line: number;
  category: Category;
  subCategory?: FieldSubCategory;
}

function isPrivate(node: PropertyDeclaration | MethodDeclaration | GetAccessorDeclaration | SetAccessorDeclaration): boolean {
  const name = node.getName();
  // # prefix means private
  if (name.startsWith('#')) return true;
  // Check for private keyword
  return node.hasModifier(SyntaxKind.PrivateKeyword);
}

function isProtected(node: PropertyDeclaration | MethodDeclaration | GetAccessorDeclaration | SetAccessorDeclaration): boolean {
  return node.hasModifier(SyntaxKind.ProtectedKeyword);
}

function getInitializerText(prop: PropertyDeclaration): string {
  const initializer = prop.getInitializer();
  return initializer ? initializer.getText() : '';
}

function classifyFieldSubCategory(prop: PropertyDeclaration): FieldSubCategory {
  const initText = getInitializerText(prop);

  if (/\bviewChild\s*[<(]/.test(initText) || /\bviewChildren\s*[<(]/.test(initText) ||
      /\bcontentChild\s*[<(]/.test(initText) || /\bcontentChildren\s*[<(]/.test(initText)) {
    return FieldSubCategory.VIEWCHILD;
  }
  if (/\binput\s*[<(]/.test(initText)) {
    return FieldSubCategory.INPUT;
  }
  if (/\boutput\s*[<(]/.test(initText)) {
    return FieldSubCategory.OUTPUT;
  }
  if (/\bcomputed\s*\(/.test(initText)) {
    return FieldSubCategory.COMPUTED;
  }
  if (/\bsignal\s*[<(]/.test(initText)) {
    return FieldSubCategory.SIGNAL;
  }

  return FieldSubCategory.VARIABLE;
}

function classifyProperty(prop: PropertyDeclaration): ClassifiedMember {
  const name = prop.getName();
  const line = prop.getStartLineNumber();
  const initText = getInitializerText(prop);

  // Check if inject()
  if (/\binject\s*[<(]/.test(initText)) {
    return { name, line, category: Category.INJECT };
  }

  // Check if static
  if (prop.hasModifier(SyntaxKind.StaticKeyword)) {
    return { name, line, category: Category.STATIC };
  }

  // Determine access level
  if (isPrivate(prop)) {
    return { name, line, category: Category.PRIVATE_FIELD, subCategory: classifyFieldSubCategory(prop) };
  }
  if (isProtected(prop)) {
    return { name, line, category: Category.PROTECTED_FIELD, subCategory: classifyFieldSubCategory(prop) };
  }

  // Public field
  return { name, line, category: Category.PUBLIC_FIELD, subCategory: classifyFieldSubCategory(prop) };
}

function classifyMethod(method: MethodDeclaration): ClassifiedMember {
  const name = method.getName();
  const line = method.getStartLineNumber();

  // Lifecycle hooks are always in the lifecycle category
  if (LIFECYCLE_HOOKS.has(name)) {
    return { name, line, category: Category.LIFECYCLE };
  }

  if (isPrivate(method)) {
    return { name, line, category: Category.PRIVATE_METHOD };
  }
  if (isProtected(method)) {
    return { name, line, category: Category.PROTECTED_METHOD };
  }

  return { name, line, category: Category.PUBLIC_METHOD };
}

function classifyAccessor(accessor: GetAccessorDeclaration | SetAccessorDeclaration): ClassifiedMember {
  const name = accessor.getName();
  const line = accessor.getStartLineNumber();
  return { name, line, category: Category.GETTER_SETTER };
}

function analyzeClass(classDecl: ClassDeclaration): string[] {
  const violations: string[] = [];
  const members: ClassifiedMember[] = [];

  // Classify all members
  for (const member of classDecl.getMembers()) {
    if (Node.isPropertyDeclaration(member)) {
      members.push(classifyProperty(member));
    } else if (Node.isMethodDeclaration(member)) {
      members.push(classifyMethod(member));
    } else if (Node.isConstructorDeclaration(member)) {
      members.push({ name: 'constructor', line: member.getStartLineNumber(), category: Category.CONSTRUCTOR });
    } else if (Node.isGetAccessorDeclaration(member) || Node.isSetAccessorDeclaration(member)) {
      members.push(classifyAccessor(member));
    }
  }

  if (members.length <= 1) {
    return violations;
  }

  // Check category ordering
  for (let i = 1; i < members.length; i++) {
    const prev = members[i - 1];
    const curr = members[i];

    if (curr.category < prev.category) {
      violations.push(
        `Line ${curr.line}: \`${curr.name}\` (${CATEGORY_LABELS[curr.category]}) appears after \`${prev.name}\` (${CATEGORY_LABELS[prev.category]}) at line ${prev.line}`
      );
    }

    // Check sub-category ordering within the same field category
    if (curr.category === prev.category && curr.subCategory !== undefined && prev.subCategory !== undefined) {
      if (curr.subCategory < prev.subCategory) {
        violations.push(
          `Line ${curr.line}: \`${curr.name}\` (${SUBCATEGORY_LABELS[curr.subCategory]}) appears after \`${prev.name}\` (${SUBCATEGORY_LABELS[prev.subCategory]}) at line ${prev.line}`
        );
      }
    }
  }

  return violations;
}

function main() {
  const filePath = process.argv[2];
  if (!filePath) {
    console.log('- [ ] **Class structure**: No file path provided');
    process.exit(1);
  }

  const absolutePath = path.resolve(filePath);

  const project = new Project({
    compilerOptions: { strict: false, skipLibCheck: true },
    skipAddingFilesFromTsConfig: true,
    skipFileDependencyResolution: true,
  });

  let sourceFile;
  try {
    sourceFile = project.addSourceFileAtPath(absolutePath);
  } catch {
    console.log('- [ ] **Class structure**: Could not parse file');
    process.exit(0);
  }

  if (!sourceFile) {
    console.log('- [ ] **Class structure**: Could not parse file');
    process.exit(0);
  }

  const classes = sourceFile.getClasses();
  if (classes.length === 0) {
    console.log('- [x] **Class structure**: No class found (skipped) -- PASS');
    process.exit(0);
  }

  let hasViolations = false;

  for (const classDecl of classes) {
    const className = classDecl.getName() || '(anonymous)';
    const violations = analyzeClass(classDecl);

    if (violations.length === 0) {
      console.log(`- [x] **Class structure** (\`${className}\`): Member ordering correct -- PASS`);
    } else {
      hasViolations = true;
      console.log(`- [ ] **Class structure** (\`${className}\`) -- **FAIL** (${violations.length} ordering issue(s))`);
      for (const v of violations) {
        console.log(`  - ${v}`);
      }
    }
  }

  process.exit(0);
}

main();
