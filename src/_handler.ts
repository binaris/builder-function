import path from 'path';
import { tmpdir } from 'os';
import { createHash } from 'crypto';
import through from 'through2';
import express, { Request } from 'express';
import { createReadStream, mkdtemp } from 'mz/fs';
import tar from 'tar';
import fetch from 'node-fetch';
import { build, createTarball } from '@reshuffle/build-utils';

interface ReqParams {
  getUrl: string;
  putUrl: string;
  finishMarker: string;
}

const app = express();
app.set('trust proxy', true);

app.use(express.json());

app.post('/build', async (req, res) => {

  let params: ReqParams;
  try {
    params = validateRequest(req);
  } catch (err) {
    console.error(err);
    res.sendStatus(400);
    return;
  }

  const { getUrl, putUrl, finishMarker } = params;

  try {
    const downloadDir = await getSourceCode(getUrl);
    const buildDir = await build(downloadDir);
    const tarballPath = await createTarball(buildDir);
    const digest = await uploadTarFile(tarballPath, putUrl);
    res.status(200);
    res.end(JSON.stringify({
      digest,
    }));
  } catch (err) {
    console.error(err);
    res.sendStatus(500);
  } finally {
    console.log(finishMarker);
  }
});

function validateRequest(req: Request): ReqParams {
  const { getUrl, putUrl, finishMarker } = req.body;
  if (typeof getUrl !== 'string') {
    throw new Error('"getUrl" must be a string.');
  }
  if (typeof putUrl !== 'string') {
    throw new Error('"putUrl" must be a string.');
  }
  if (typeof finishMarker !== 'string') {
    throw new Error('"finishMarker" must be a string.');
  }
  return {
    getUrl,
    putUrl,
    finishMarker,
  };
}

async function getSourceCode(tarFileUrl: string): Promise<string> {
  console.log('Getting source code...');
  const { ok, status, statusText, body } = await fetch(tarFileUrl);

  if (!ok) {
    throw new Error(`Request failed with status: ${status} - ${statusText}`);
  }

  const downloadDir = await mkdtemp(path.resolve(tmpdir(), 'reshuffle-app-'), { encoding: 'utf8' });

  await new Promise<void>((resolve, reject) => {
    body.pipe(tar.extract({ cwd: downloadDir }))
      .on('error', (err) => {
        reject(err);
      })
      .on('close', () => {
        resolve();
      });
  });

  console.log('Download complete!');

  return downloadDir;
}

async function uploadTarFile(tarballPath: string, url: string): Promise<string> {
  console.log('Uploading project...');

  const hash = createHash('sha256');
  const { ok, status, statusText } = await fetch(url, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/gzip',
    },
    body: createReadStream(tarballPath).pipe(through(function(chunk, _env, cb) {
      // This updates the hash/digest while reading and uploading the file
      hash.update(chunk);
      this.push(chunk);
      cb();
    })),
  });

  if (!ok) {
    throw new Error(`Upload failed with status: ${status} - ${statusText}`);
  }
  console.log('done!');

  return hash.digest('hex').toString();
}

export default app;
