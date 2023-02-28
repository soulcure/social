import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/country_model.dart';
import 'country_page.dart';

class CountryPageWeb extends CountryPage {

  @override
  // ignore: overridden_fields
  final Function(CountryModel) callback;

  const CountryPageWeb({
    this.callback
  }) : super(callback: callback);

  @override
  _CountryPageWebState createState() => _CountryPageWebState();
}

class _CountryPageWebState extends CountryPageState<CountryPageWeb> {

  @override
  // ignore: overridden_fields
  final int suspensionHeight = 32;
  @override
  // ignore: overridden_fields
  final int itemHeight = 32;

  @override
  Widget buildPickItem(CountryModel model) {
    return Column(
      children: <Widget>[
        Offstage(
          offstage: !(model.isShowSuspension == true),
          child: buildSusWidget(model.key),
        ),
        GestureDetector(
          onTap: () {
            if (widget.callback != null) {
              widget.callback(model);
            } else {
              Navigator.of(context).pop(model);
            }
          },
          child: Container(
            height: 32,
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).backgroundColor,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              '${model.countryName}  +${model.phoneCode}',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildSusWidget(String susTag) {
    susTag = susTag == '' ? '最热地区'.tr : susTag;
    susTag = susTag == "#" ? "最热地区".tr : susTag;
    return Container(
      alignment: Alignment.centerLeft,
      height: 32,
      color: Theme.of(context).backgroundColor,
      padding: const EdgeInsets.only(left: 15,),
      child: Text(susTag,
          style: Theme.of(context).textTheme.bodyText2),
    );
  }
  
}
