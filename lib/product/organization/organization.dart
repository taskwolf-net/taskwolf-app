import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:taskwolf_app/product/base/page.dart';
import 'package:taskwolf_app/product/organization/team.dart';
import 'package:taskwolf_app/request/request.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';

class OrganizationPage extends StatelessWidget {
  OrganizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return FutureBuilder<dynamic>(
      future: findAllOrganizations(context),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        return ProductPage(name: Locales.string(context, "product.organizations.title"),
          content: Scaffold(
            body: Center(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: const LocaleText("product.organizations.your.organizations",
                      textAlign: TextAlign.center, style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  ),
                  createOrganizationList(List<Map<String, dynamic>>.from(snapshot.data ?? []),
                    snapshot.data, isLight, context)
                ]
              ),
            ),
          )
        );
      }
    );
  }

  createOrganizationList(
    List<Map<String, dynamic>> organizations, raw, isLight, context
  ) {
    if (raw == null) {
      return Container();
    }
    if (organizations.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.organizations.empty",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)
      );
    }
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        width: 750,
        child: ListView.separated(
          itemBuilder: (builder, index) {
            return Card(child: createOrganizationEntry(organizations[index],
              isLight, context));
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 20,
          ),
          itemCount: organizations.length,
        ),
      ),
    );
  }

  createOrganizationEntry(organization, isLight, context) {
    return ListTile(
      title: Text(organization["name"]),
      subtitle: Text(Locales.string(context, "product.organizations.owner") + ": " + organization["ownerName"]),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
          width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      onTap: () => {
        Navigator.push(context, MaterialPageRoute(builder: (context) =>
          TeamPage(organization: organization["id"])))
      },
    );
  }

  findAllOrganizations(context) async {
    var response = await Request.get(context: context,
      url: "/organizations/all/").send();
    return jsonDecode(response.body)["organizations"];
  }
}