import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/blocks/fluent_settings_block.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/cards/fluent_setting_card.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/pages/fluent_settings_page.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/settings_screen/settings_screen_view_model.dart';

part 'settings_screen_view.helpers.dart';

class SettingsScreenView extends ScreenViewBase<SettingsScreenViewModel, SettingsScreenController> {

  const SettingsScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return FluentTheme(
      data: FluentThemeData(),
      child: Builder(
        builder: (context) {
          return Observer(builder: (_) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: _navigationView),
              ],
            );
          });
        },
      ),
    );
  }

  Widget get _navigationView {
    return NavigationView(
      pane: NavigationPane(
        selected: viewModel.paneIndex,
        onChanged: controller.onNavigationPaneIndexChanged,
        items: [
          PaneItemSeparator(color: Colors.transparent),
          PaneItem(
            icon: Icon(FluentIcons.settings),
            title: Text("General"),
            body: _generalSettings,
          ),
          PaneItem(
            icon: Icon(FluentIcons.devices4),
            title: Text("Hardware"),
            body: _hardwareSettings,
          ),
          PaneItem(
            icon: Icon(FluentIcons.send),
            title: Text("Output"),
            body: _outputSettings,
          ),
        ],
      ),
    );
  }

  Widget get _generalSettings {
    return FluentSettingsPage(
      title: "General",
      blocks: [
        FluentSettingsBlock(
          title: "Settings",
          settings: [
            _getInput(
              icon: FluentIcons.timer,
              title: "Capture delay",
              subtitle: 'In seconds',
              value: () => viewModel.captureDelaySecondsSetting,
              onChanged: controller.onCaptureDelaySecondsChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget get _hardwareSettings {
    return FluentSettingsPage(
      title: "Hardware",
      blocks: [
        FluentSettingsBlock(
          title: "Camera settings",
          settings: [
            _getComboBoxCard(
              icon: FluentIcons.camera,
              title: "Live view method",
              subtitle: "Method used for live previewing",
              items: viewModel.liveViewMethods,
              value: () => viewModel.liveViewMethodSetting,
              onChanged: controller.onLiveViewMethodChanged,
            ),
            _getComboBoxCard(
              icon: FluentIcons.camera,
              title: "Capture method",
              subtitle: "Method used for capturing final images",
              items: viewModel.captureMethods,
              value: () => viewModel.captureMethodSetting,
              onChanged: controller.onCaptureMethodChanged,
            ),
            _getTextInput(
              icon: FluentIcons.folder,
              title: "Capture location",
              subtitle: "Location to look for captured images",
              controller: controller.captureLocationController,
              onChanged: controller.onCaptureLocationChanged,
            ),
          ],
        ),
        FluentSettingsBlock(
          title: "Printing",
          settings: [
            FluentSettingCard(
              icon: FluentIcons.print,
              title: "Printer",
              subtitle: "Which printer to use for printing photos",
              child: Row(
                children: [
                  Button(
                    onPressed: viewModel.setPrinterList,
                    // style: ButtonStyle(backgroundColor: ButtonState.all(Colors.white)),
                    child: const Text('Refresh'),
                  ),
                  SizedBox(width: 10,),
                  IconButton(
                    onPressed: viewModel.setPrinterList,
                    style: ButtonStyle(
                      border: ButtonState.all(BorderSide(color: Color(0xfff0f0f0))),
                    ),
                    icon: const Icon(FluentIcons.refresh),
                  ),
                  SizedBox(width: 10,),
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 150),
                    child: Observer(builder: (_) {
                      return ComboBox<String>(
                        items: viewModel.printerOptions,
                        value: viewModel.printerSetting,
                        onChanged: controller.onPrinterChanged,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _outputSettings {
    return FluentSettingsPage(
      title: "Output",
      blocks: [
        FluentSettingsBlock(
          title: "Local",
          settings: [
            _getTextInput(
              icon: FluentIcons.folder,
              title: "Local photo storage location",
              subtitle: "Location where the output images will be stored",
              controller: controller.localFolderSettingController,
              onChanged: controller.onLocalFolderChanged,
            ),
          ],
        ),
        FluentSettingsBlock(
          title: "Share using internet",
          settings: [
            _getTextInput(
              icon: FluentIcons.my_network,
              title: "Firefox Send URL",
              subtitle: "Firefox Send Server URL",
              controller: controller.firefoxSendServerUrlController,
              onChanged: controller.onFirefoxSendServerUrlChanged,
            ),
          ],
        ),
      ],
    );
  }

}
