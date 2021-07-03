{ pullImage }:
{
  mssql = pullImage {
    imageName = "bitwarden/mssql";
    imageDigest = "sha256:a88af089415a486c1799a1abe721cf52d1ad6a2ca4a5efce27d6b5a2e14047ce";
    sha256 = "0vgk0p73pwmia9jpxvpwywcmnmj4hfizpz3dr18v0wg2rn58al76";
    finalImageName = "bitwarden/mssql";
    finalImageTag = "1.41.4";
  };

  web = pullImage {
    imageName = "bitwarden/web";
    imageDigest = "sha256:69e2d10add2a3192ec6b26c63f538a42b88ddbaafa465b447c4183e5f9ef5172";
    sha256 = "1v315s2bp1bh29kvkldnaf50lk6bakwzknsnlnlyfvcbhy0vaqvv";
    finalImageName = "bitwarden/web";
    finalImageTag = "2.21.0";
  };

  attachments = pullImage {
    imageName = "bitwarden/attachments";
    imageDigest = "sha256:25d619b35c255230d3893b3ac48a5d8f35f8d5c8da3565e35e22361e5173c9ed";
    sha256 = "0dryrsx3fzyfrfvvm97rn06zirl4cd12712wqyqs2ranr5zzgpgl";
    finalImageName = "bitwarden/attachments";
    finalImageTag = "1.41.4";
  };

  api = pullImage {
    imageName = "bitwarden/api";
    imageDigest = "sha256:783cf7916c14fab30e4b68deceaf46cbaad24426f3f375afd016f89f75467da4";
    sha256 = "1p48ggs8imwbfkpb0xa80ja49mwnvrpgvjywmlp9gd800mz9hp95";
    finalImageName = "bitwarden/api";
    finalImageTag = "1.41.4";
  };

  identity = pullImage {
    imageName = "bitwarden/identity";
    imageDigest = "sha256:8bc9a5237df5ff692885a89d4d5b1adc894f814fea1dbf9323a7750e8e3c908b";
    sha256 = "1j2mhpsl8hgnvzxmwgcv09vwzkk8dxy0zr624bfmim95smn9ydf3";
    finalImageName = "bitwarden/identity";
    finalImageTag = "1.41.4";
  };

  sso = pullImage {
    imageName = "bitwarden/sso";
    imageDigest = "sha256:9e5e864e21c6896c1c0907def06ccdc83001af871285cbe4a4f4b9f9b139ac38";
    sha256 = "1zvcc9c3mddp9c8yqd74a0y4dji0rn7zq45l1gbx6q58im05ayfy";
    finalImageName = "bitwarden/sso";
    finalImageTag = "1.41.4";
  };

  admin = pullImage {
    imageName = "bitwarden/admin";
    imageDigest = "sha256:f03c5063d213b02c1b21492043e27d780114768ddfb3779151c69e61f779bdd1";
    sha256 = "0jpz8zh12l85z29yvgdl2xgkrl7jqcjk7if8nhh04mq5adbyaalc";
    finalImageName = "bitwarden/admin";
    finalImageTag = "1.41.4";
  };

  portal = pullImage {
    imageName = "bitwarden/portal";
    imageDigest = "sha256:c2078f831eea57052d2d882dee9701aba9e79e96bac994a047b43d49d8a8743b";
    sha256 = "0q2pl1i1frnx4azlv9c1d5vy1a95d8g61p3hjam56042v8jlnp7j";
    finalImageName = "bitwarden/portal";
    finalImageTag = "1.41.4";
  };

  icons = pullImage {
    imageName = "bitwarden/icons";
    imageDigest = "sha256:70a6cfe47ff07bbe0317e7b3f0ac364b494ce5b13c975f26c9c67bf7b559c934";
    sha256 = "0y23z1w0ny6r9if642cnrnmbyxrf5l5lpy9nj0yg8jq2yqk85223";
    finalImageName = "bitwarden/icons";
    finalImageTag = "1.41.4";
  };

  notifications = pullImage {
    imageName = "bitwarden/notifications";
    imageDigest = "sha256:7decb15ec496e0cb07336309742210ae6346ff13beff351b0d421e2415319080";
    sha256 = "0a2afq1nxa170v6sf9sabyb0a7fby3rdqj18yvv143kldg6w6k9x";
    finalImageName = "bitwarden/notifications";
    finalImageTag = "1.41.4";
  };

  events = pullImage {
    imageName = "bitwarden/events";
    imageDigest = "sha256:7ee3d8e464feb1240bdc376d76b549580dc72d86ad33b8c9b5733d677ef58a91";
    sha256 = "18cym6a9f575z46vl1rx1ggla0pi0vv6gblhm5ffmk1a3izcpzs5";
    finalImageName = "bitwarden/events";
    finalImageTag = "1.41.4";
  };

  nginx = pullImage {
    imageName = "bitwarden/nginx";
    imageDigest = "sha256:89c7f4bf01f7750ce99f70faa11e13f99d230a78bbe7ba842fee889cf225c445";
    sha256 = "0dvb4a0f31fcq1qy0sb9msnbkccv03ap74ll79q3n4c5fb6wxs32";
    finalImageName = "bitwarden/nginx";
    finalImageTag = "1.41.4";
  };
}