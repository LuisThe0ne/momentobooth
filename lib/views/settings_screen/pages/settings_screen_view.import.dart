part of '../settings_screen_view.dart';

Widget _getImportSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsPage(
    title: "Import",
    blocks: [
      Text("Drop a settings stub here to import it."),
      SizedBox(height: 16.0,),
      Row(
        children: [
          Button(child: Text("Open settings folder"), onPressed: () async => await launchUrl(Uri.parse("file:///$appDataPath"))),
        ],
      ),
      SizedBox(height: 16.0,),
      MyDropRegion(),
    ]
  );
}
