
function init() {
 $("p1").focus();
}

function apply()
{
 p1 = $('p1').value;
 p2 = $('p2').value;
 s1 = $('s1').value;

 $('p1').value = "";
 $('p2').value = "";
 $('s1').value = "";

 if(p1 != p2) {
   setText('msg', "(E) Die Passw&ouml;rter sind nicht identisch.");
   return;
              }
 else {
   if(p1 == "") {
     setText('msg', "Keine Passwort&auml;nderung.");
                } 
   else {
   setText('msg', "(I) Das Passwort wird ge&auml;ndert. Bitte die Seite neu laden.");
   send("/cgi-bin/password", { func : "set_password", pass1 : p1, pass2 : p2 }, function(data) {
   setText('msg', data);
   });
        }
      }

 if(s1 == "") {
   setText('msg', "");
              } 
 else {
   send("/cgi-bin/sshpubkey", { func : "set_sshpubkey", sshpubkey : s1}, function(data) {
   setText('msg', data);
   });
      }
}
