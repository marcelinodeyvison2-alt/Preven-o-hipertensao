import { Directory, File, Paths } from 'expo-file-system';
import { getItem, setItem } from './storage';
import { DownloadedTrack, Track } from '../types';

function downloadsKey(uid: string) {
  return `downloads:${uid}`;
}

function getDownloadsDir(): Directory {
  const dir = new Directory(Paths.document, 'downloads');
  if (!dir.exists) dir.create();
  return dir;
}

export async function getDownloads(uid: string): Promise<DownloadedTrack[]> {
  return (await getItem<DownloadedTrack[]>(downloadsKey(uid))) ?? [];
}

export async function isDownloaded(uid: string, trackId: string): Promise<boolean> {
  const downloads = await getDownloads(uid);
  return downloads.some((d) => d.track.id === trackId);
}

export async function downloadTrack(
  uid: string,
  track: Track,
  onProgress?: (progress: number) => void
): Promise<DownloadedTrack> {
  const dir = getDownloadsDir();
  const dest = new File(dir, `${track.id}.mp3`);
  if (dest.exists) {
    dest.delete();
  }

  const task = File.createDownloadTask(track.streamUrl, dest, {
    onProgress: ({ bytesWritten, totalBytes }) => {
      if (totalBytes > 0) onProgress?.(bytesWritten / totalBytes);
    },
  });

  const file = await task.downloadAsync();
  if (!file) {
    throw new Error('Download cancelado');
  }

  const entry: DownloadedTrack = { track, localUri: file.uri, downloadedAt: Date.now() };
  const existing = await getDownloads(uid);
  const next = [...existing.filter((d) => d.track.id !== track.id), entry];
  await setItem(downloadsKey(uid), next);
  return entry;
}

export async function deleteDownload(uid: string, trackId: string): Promise<void> {
  const existing = await getDownloads(uid);
  const entry = existing.find((d) => d.track.id === trackId);
  if (entry) {
    try {
      const file = new File(entry.localUri);
      if (file.exists) file.delete();
    } catch {
      // file already gone, ignore
    }
  }
  await setItem(
    downloadsKey(uid),
    existing.filter((d) => d.track.id !== trackId)
  );
}
