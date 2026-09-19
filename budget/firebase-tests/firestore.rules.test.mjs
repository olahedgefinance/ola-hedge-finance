import fs from 'node:fs';
import test, { after, before, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
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
  setDoc,
  updateDoc,
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

async function seedBudget() {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'budgets/shared'), {
      owner: owner.uid,
      ownerEmail: owner.email,
      members: [owner.email, member.email],
      name: 'Household',
    });
  });
}

function dbFor(user) {
  return environment
    .authenticatedContext(user.uid, { email: user.email })
    .firestore();
}

test('unauthenticated clients cannot read or write shared budgets', async () => {
  const db = environment.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'budgets/shared')));
  await assertFails(setDoc(doc(db, 'budgets/new'), { owner: 'anonymous' }));
});

test('owner can create, read, update membership, and delete a budget', async () => {
  const db = dbFor(owner);
  const ref = doc(db, 'budgets/owned');
  await assertSucceeds(setDoc(ref, {
    owner: owner.uid,
    ownerEmail: owner.email,
    members: [owner.email],
    name: 'Owned',
  }));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, { members: [owner.email, member.email] }));
  await assertSucceeds(deleteDoc(ref));
});

test('invited members can read and edit content but cannot change access', async () => {
  await seedBudget();
  const db = dbFor(member);
  const budget = doc(db, 'budgets/shared');
  await assertSucceeds(getDoc(budget));
  await assertSucceeds(updateDoc(budget, { name: 'Updated household' }));
  await assertFails(updateDoc(budget, { members: [member.email] }));
  await assertFails(deleteDoc(budget));
  await assertSucceeds(setDoc(doc(db, 'budgets/shared/transactions/tx-1'), {
    amount: 12.34,
  }));
});

test('uninvited users cannot access a budget or its transactions', async () => {
  await seedBudget();
  const db = dbFor(stranger);
  await assertFails(getDoc(doc(db, 'budgets/shared')));
  await assertFails(setDoc(doc(db, 'budgets/shared/transactions/tx-1'), {
    amount: 12.34,
  }));
});

test('feedback is authenticated create-only', async () => {
  const ref = collection(dbFor(owner), 'feedback');
  const created = await assertSucceeds(addDoc(ref, { rating: 4 }));
  await assertFails(getDoc(created));
  await assertFails(updateDoc(created, { rating: 5 }));
  await assertFails(deleteDoc(created));
});
