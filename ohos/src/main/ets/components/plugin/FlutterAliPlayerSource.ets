import { VidPlayerConfigGen } from 'premierlibrary/src/main/ets/com/aliyun/player/VidPlayerConfigGen';
import { Definition } from 'premierlibrary/src/main/ets/com/aliyun/player/source/Definition';
import { LiveEncryptionType, LiveSts } from 'premierlibrary/src/main/ets/com/aliyun/player/source/LiveSts';
import { VidAuth } from 'premierlibrary/src/main/ets/com/aliyun/player/source/VidAuth';
import { VidMps } from 'premierlibrary/src/main/ets/com/aliyun/player/source/VidMps';
import { VidSts } from 'premierlibrary/src/main/ets/com/aliyun/player/source/VidSts';
import { VidSourceBase } from 'premierlibrary/src/main/ets/com/aliyun/player/source/VidSourceBase';

type SourceArgs = Record<string, ESObject>;

function required(arg: SourceArgs, key: string): string {
  const value: ESObject = arg[key];
  if (value == null || String(value).trim().length === 0) {
    throw new Error(`INVALID_ARGUMENT: ${key} is required`);
  }
  return String(value);
}

function optional(arg: SourceArgs, key: string): string | null {
  const value: ESObject = arg[key];
  if (value == null || String(value).trim().length === 0) {
    return null;
  }
  return String(value);
}

function definitions(values: ESObject): Definition[] {
  if (!Array.isArray(values)) {
    return [];
  }
  const result: Definition[] = [];
  const supported: Record<string, Definition> = {
    'FD': Definition.DEFINITION_FD,
    'LD': Definition.DEFINITION_LD,
    'SD': Definition.DEFINITION_SD,
    'HD': Definition.DEFINITION_HD,
    'OD': Definition.DEFINITION_OD,
    '2K': Definition.DEFINITION_2K,
    '4K': Definition.DEFINITION_4K,
    'SQ': Definition.DEFINITION_SQ,
    'HQ': Definition.DEFINITION_HQ,
    'AUTO': Definition.DEFINITION_AUTO
  };
  const valueList: string[] = values as string[];
  for (const value of valueList) {
    const definition: Definition = supported[String(value).toUpperCase()];
    if (definition != null) {
      result.push(definition);
    }
  }
  return result;
}

function applyVidOptions(source: VidSourceBase, arg: SourceArgs, quality: (value: string, force: boolean) => void): void {
  const qualityValue: string | null = optional(arg, 'quality');
  if (qualityValue != null) {
    quality(qualityValue, Boolean(arg['forceQuality']));
  }

  const definitionList: Definition[] = definitions(arg['definitionList']);
  if (definitionList.length > 0) {
    source.setDefinition(definitionList);
  }

  const playConfig: ESObject = arg['playConfig'];
  const previewTime: ESObject = arg['previewTime'];
  if (playConfig != null || previewTime != null) {
    const config: VidPlayerConfigGen = new VidPlayerConfigGen();
    if (playConfig != null) {
      let configMap: ESObject = playConfig;
      if (typeof playConfig === 'string') {
        configMap = JSON.parse(playConfig as string) as ESObject;
      }
      if (configMap != null && typeof configMap === 'object') {
        for (const key of Object.keys(configMap as Record<string, ESObject>)) {
          const value: ESObject = (configMap as Record<string, ESObject>)[key];
          if (typeof value === 'number') {
            config.addPlayerConfigNumber(key, value as number);
          } else if (typeof value === 'string') {
            config.addPlayerConfigString(key, value as string);
          }
        }
      }
    }
    if (previewTime != null && String(previewTime).length > 0) {
      config.setPreviewTime(Number(previewTime));
    }
    source.setPlayerConfig(config);
  }
}

export function createVidAuth(arg: SourceArgs): VidAuth {
  const source: VidAuth = new VidAuth();
  source.setVid(required(arg, 'vid'));
  source.setPlayAuth(required(arg, 'playAuth'));
  const region: string | null = optional(arg, 'region');
  if (region != null) {
    source.setRegion(region);
  }
  applyVidOptions(source, arg, (quality: string, force: boolean) => source.setQuality(quality, force));
  return source;
}

export function createVidSts(arg: SourceArgs): VidSts {
  const source: VidSts = new VidSts();
  source.setVid(required(arg, 'vid'));
  source.setAccessKeyId(required(arg, 'accessKeyId'));
  source.setAccessKeySecret(required(arg, 'accessKeySecret'));
  source.setSecurityToken(required(arg, 'securityToken'));
  const region: string | null = optional(arg, 'region');
  if (region != null) {
    source.setRegion(region);
  }
  applyVidOptions(source, arg, (quality: string, force: boolean) => source.setQuality(quality, force));
  return source;
}

export function createVidMps(arg: SourceArgs): VidMps {
  const source: VidMps = new VidMps();
  source.setMediaId(required(arg, 'vid'));
  source.setAccessKeyId(required(arg, 'accessKeyId'));
  source.setAccessKeySecret(required(arg, 'accessKeySecret'));
  source.setSecurityToken(required(arg, 'securityToken'));
  const fields: string[] = ['region', 'playDomain', 'authInfo', 'hlsUriToken'];
  for (const key of fields) {
    const value: string | null = optional(arg, key);
    if (value == null) {
      continue;
    }
    if (key === 'region') {
      source.setRegion(value);
    } else if (key === 'playDomain') {
      source.setPlayDomain(value);
    } else if (key === 'authInfo') {
      source.setAuthInfo(value);
    } else {
      source.setHlsUriToken(value);
    }
  }
  applyVidOptions(source, arg, (quality: string, force: boolean) => source.setQuality(quality, force));
  return source;
}

function encryptionType(value: ESObject): LiveEncryptionType {
  const normalized: string = String(value).toLowerCase();
  if (normalized === '1' || normalized === 'alivod' || normalized === 'aliencryption') {
    return LiveEncryptionType.AliEncryption;
  }
  if (normalized === '2' || normalized === 'fairplay' || normalized === 'widevine_fairplay') {
    return LiveEncryptionType.WideVine_FairPlay;
  }
  return LiveEncryptionType.NoEncryption;
}

export function createLiveSts(arg: SourceArgs): LiveSts {
  const source: LiveSts = new LiveSts();
  source.setUrl(required(arg, 'url'));
  source.setAccessKeyId(required(arg, 'accessKeyId'));
  source.setAccessKeySecret(required(arg, 'accessKeySecret'));
  source.setSecurityToken(required(arg, 'securityToken'));
  const fields: string[] = ['region', 'domain', 'app', 'stream'];
  for (const key of fields) {
    const value: string | null = optional(arg, key);
    if (value == null) {
      continue;
    }
    if (key === 'region') {
      source.setRegion(value);
    } else if (key === 'domain') {
      source.setDomain(value);
    } else if (key === 'app') {
      source.setApp(value);
    } else {
      source.setStream(value);
    }
  }
  if (arg['encryptionType'] != null) {
    source.setEncryptionType(encryptionType(arg['encryptionType']));
  }
  return source;
}
