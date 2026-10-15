
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { logger } from 'utils';

export const GlobalThemeSetColorMode = (context: common.UIAbilityContext, colorMode: ConfigurationConstant.ColorMode) => {
  try {
    context.getApplicationContext().setColorMode(colorMode);
  } catch (error) {
    logger.error('Failed to set theme mode. Cause: ', JSON.stringify(error));
  }
}

export const GlobalThemeSetAutoColorMode = (context: common.UIAbilityContext) => {
  GlobalThemeSetColorMode(context, ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
}

export const GlobalThemeSetDarkColorMode = (context: common.UIAbilityContext) => {
  GlobalThemeSetColorMode(context, ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
}

export const GlobalThemeSetLightColorMode = (context: common.UIAbilityContext) => {
  GlobalThemeSetColorMode(context, ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
}