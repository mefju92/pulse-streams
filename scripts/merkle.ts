import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { parse } from 'csv-parse/sync';
import { Command } from 'commander';
import keccak256 from 'keccak256';
import { MerkleTree } from 'merkletreejs';

type Row = { address: string; amount: string };

const program = new Command();
program
  .requiredOption('--csv <path>', 'CSV file with columns address,amount')
  .option('--out <dir>', 'Output directory', './out')
  .parse(process.argv);
const opts = program.opts();

const csv = readFileSync(opts.csv, 'utf8');
const rows = parse(csv, { columns: true, skip_empty_lines: true }) as Row[];

const leaves = rows.map((r) => {
  const addr = r.address.trim();
  const amt = r.amount.trim();
  const addrBuf = Buffer.from(addr.replace(/^0x/, ''), 'hex');
  const amtBuf = Buffer.from(BigInt(amt).toString(16).padStart(64, '0'), 'hex');
  const leaf = Buffer.from(keccak256(Buffer.concat([addrBuf, amtBuf])));
  return { address: addr, amount: amt, leaf };
});

const tree = new MerkleTree(leaves.map(l => l.leaf), keccak256, { sortPairs: true });
const root = '0x' + tree.getRoot().toString('hex');

if (!existsSync(opts.out)) mkdirSync(opts.out, { recursive: true });
writeFileSync(`${opts.out}/root.json`, JSON.stringify({ merkleRoot: root }, null, 2));
writeFileSync(`${opts.out}/leaves.json`, JSON.stringify(leaves.map(l => ({ address: l.address, amount: l.amount, leaf: '0x'+l.leaf.toString('hex'), proof: tree.getHexProof(l.leaf) })), null, 2));

console.log('Merkle root:', root);
