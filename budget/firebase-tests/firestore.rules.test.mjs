import fs from 'node:fs';
import test, { after, before, beforeEach } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const projectId = 'ola-hedge-finance-rules-test';
const owner = { uid: 'owner', email: 'owner@example.test' };
const member = { uid: 'member', email: 'member@example.test' };
const stranger = { uid: 'stranger', email: 'stranger@example.test' };
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => environment.clearFirestore());
after(async () => environment.cleanup());

function budgetData(overrides = {}) {
  return {
    owner: owner.uid,
    ownerEmail: owner.email,
    members: [member.email],
    name: 'Household',
    ...overrides,
  };
}

async function seedBudget(overrides = {}) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'budgets/shared'),
      budgetData(overrides),
    );
  });
}

function dbFor(user, tokenOverrides = {}) {
  return environment
    .authenticatedContext(user.uid, {
      email: user.email,
      firebase: { sign_in_provider: 'google.com' },
      ...tokenOverrides,
    })
    .firestore();
}

function anonymousAuthDb() {
  return environment
    .authenticatedContext('anonymous-user', {
      firebase: { sign_in_provider: 'anonymous' },
    })
    .firestore();
}

test('unauthenticated and anonymous-auth clients are denied', async () => {
  await seedBudget();
  const unauthenticated = environment.unauthenticatedContext().firestore();
  const anonymous = anonymousAuthDb();

  await assertFails(getDoc(doc(unauthenticated, 'budgets/shared')));
  await assertFails(setDoc(doc(unauthenticated, 'budgets/new'), budgetData()));
  await assertFails(getDoc(doc(anonymous, 'budgets/shared')));
  await assertFails(setDoc(doc(anonymous, 'budgets/new'), budgetData()));
});

test('authenticated users without a verified email are denied', async () => {
  await seedBudget();
  const noEmail = environment
    .authenticatedContext('no-email', {
      firebase: { sign_in_provider: 'google.com' },
    })
    .firestore();

  await assertFails(getDoc(doc(noEmail, 'budgets/shared')));
  await assertFails(setDoc(doc(noEmail, 'budgets/new'), budgetData({
    owner: 'no-email',
    ownerEmail: '',
    members: [''],
  })));
});

test('owner can create, read, edit content, manage members, and delete', async () => {
  const db = dbFor(owner);
  const ref = doc(db, 'budgets/owned');

  await assertSucceeds(setDoc(ref, budgetData({ members: [] })));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, { name: 'Updated' }));
  await assertSucceeds(updateDoc(ref, {
    members: [member.email],
  }));
  await assertSucceeds(deleteDoc(ref));
});

test('budget creation rejects malformed owner, email, and membership fields', async () => {
  const db = dbFor(owner);

  await assertFails(setDoc(doc(db, 'budgets/wrong-owner'), budgetData({
    owner: stranger.uid,
  })));
  await assertFails(setDoc(doc(db, 'budgets/wrong-email'), budgetData({
    ownerEmail: stranger.email,
  })));
  await assertFails(setDoc(doc(db, 'budgets/missing-owner-email'), {
    owner: owner.uid,
    members: [owner.email],
  }));
  await assertFails(setDoc(doc(db, 'budgets/members-not-list'), budgetData({
    members: owner.email,
  })));
});

test('owner identity is immutable and membership must remain a list', async () => {
  await seedBudget();
  const ref = doc(dbFor(owner), 'budgets/shared');

  await assertFails(updateDoc(ref, { owner: stranger.uid }));
  await assertFails(updateDoc(ref, { ownerEmail: stranger.email }));
  await assertSucceeds(updateDoc(ref, { members: [] }));
  await assertFails(updateDoc(ref, { members: 'not-a-list' }));
});

test('member can read and mutate non-access fields and nested transactions', async () => {
  await seedBudget();
  const db = dbFor(member);
  const budget = doc(db, 'budgets/shared');
  const transaction = doc(db, 'budgets/shared/transactions/tx-1');

  await assertSucceeds(getDoc(budget));
  await assertSucceeds(updateDoc(budget, { name: 'Updated household' }));
  await assertSucceeds(setDoc(transaction, { amount: 12.34 }));
  await assertSucceeds(getDoc(transaction));
  await assertSucceeds(updateDoc(transaction, { amount: 15 }));
  await assertSucceeds(deleteDoc(transaction));
});

test('member cannot change access fields, delete, or delete-recreate a budget', async () => {
  await seedBudget();
  const ref = doc(dbFor(member), 'budgets/shared');

  await assertFails(updateDoc(ref, { owner: member.uid }));
  await assertFails(updateDoc(ref, { ownerEmail: member.email }));
  await assertFails(updateDoc(ref, { members: [] }));
  await assertFails(deleteDoc(ref));
  await assertFails(setDoc(ref, budgetData({
    owner: member.uid,
    ownerEmail: member.email,
    members: [member.email],
  })));
});

test('stranger cannot access a budget or nested transactions', async () => {
  await seedBudget();
  const db = dbFor(stranger);

  await assertFails(getDoc(doc(db, 'budgets/shared')));
  await assertFails(updateDoc(doc(db, 'budgets/shared'), { name: 'Taken' }));
  await assertFails(setDoc(doc(db, 'budgets/shared/transactions/tx-1'), {
    amount: 12.34,
  }));
});

test('the client owner and member queries satisfy list rules', async () => {
  await seedBudget();
  const ownerQuery = query(
    collection(dbFor(owner), 'budgets'),
    where('owner', '==', owner.uid),
  );
  const memberQuery = query(
    collection(dbFor(member), 'budgets'),
    where('members', 'array-contains', member.email),
  );

  await assertSucceeds(getDocs(ownerQuery));
  await assertSucceeds(getDocs(memberQuery));
  await assertFails(getDocs(collection(dbFor(stranger), 'budgets')));
});

test('malformed stored access fields do not grant parent or nested access', async () => {
  await seedBudget({ owner: 123, ownerEmail: 456, members: 'all' });
  const db = dbFor(owner);

  await assertFails(getDoc(doc(db, 'budgets/shared')));
  await assertFails(setDoc(doc(db, 'budgets/shared/transactions/tx-1'), {
    amount: 12.34,
  }));
});

test('feedback is non-anonymous authenticated create-only', async () => {
  const created = await assertSucceeds(
    addDoc(collection(dbFor(owner), 'feedback'), { rating: 4 }),
  );

  await assertFails(addDoc(
    collection(environment.unauthenticatedContext().firestore(), 'feedback'),
    { rating: 4 },
  ));
  await assertFails(addDoc(collection(anonymousAuthDb(), 'feedback'), {
    rating: 4,
  }));
  await assertFails(getDoc(created));
  await assertFails(updateDoc(created, { rating: 5 }));
  await assertFails(deleteDoc(created));
});

test('unmatched paths are denied for authenticated users', async () => {
  const db = dbFor(owner);
  const ref = doc(db, 'admin/secrets');

  await assertFails(setDoc(ref, { value: 'denied' }));
  await assertFails(getDoc(ref));
});
