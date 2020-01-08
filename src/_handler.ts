import path from 'path';
import { tmpdir } from 'os';
import express, { Request } from 'express';
import { createReadStream, mkdtemp } from 'mz/fs';
import tar from 'tar';
import fetch from 'node-fetch';
import { build, createTarball } from '@reshuffle/build-utils';

interface ReqParams {
  getUrl: string,
  putUrl: string,
  endLabel: string,
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

  const { getUrl, putUrl, endLabel } = params;

  try {
    const downloadDir = await getSourceCode(getUrl);
    const buildDir = await build(downloadDir);
    const tarballPath = await createTarball(buildDir);
    await uploadTarFile(tarballPath, putUrl);
    res.sendStatus(200);
  } catch (err) {
    console.error(err);
    res.sendStatus(500);
  } finally {
    console.log(endLabel);
  }
});

function validateRequest(req: Request): ReqParams {
  const { getUrl, putUrl, endLabel } = req.body
  if (typeof getUrl !== 'string') {
    throw new Error('"getUrl" must be a string.');
  }
  if (typeof putUrl !== 'string') {
    throw new Error('"putUrl" must be a string.');
  }
  if (typeof endLabel !== 'string') {
    throw new Error('"endLabel" must be a string.');
  }
  return {
    getUrl,
    putUrl,
    endLabel,
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

async function uploadTarFile(tarballPath: string, url: string): Promise<void> {
  console.log('Uploading project...')
  const { ok, status, statusText } = await fetch(url, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/gzip',
    },
    body: createReadStream(tarballPath),
  });

  if (!ok) {
    throw new Error(`Upload failed with status: ${status} - ${statusText}`);
  }
  console.log('done!');

  return;
}

export default app;
