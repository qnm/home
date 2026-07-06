let
  usbc-a = "age1yubikey1qggmdwkkh5jtjq2wflyjsxgefawn4x8qm35gwmgje68nj26l5g9y2mgfpm6";
  mini-usbc = "age1yubikey1qwpxpzuer2j4tryqn87fyz2m2cl0ed7l2szn5fsy6n0ahnlwwcf8xqm0jfk";
in
{
  "aws-amber-identity-account-id.age".publicKeys = [ usbc-a mini-usbc ];
  "aws-amber-domain-owner.age".publicKeys = [ usbc-a mini-usbc ];
}
