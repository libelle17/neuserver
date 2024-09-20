<?php 
    IF ($_SESSION['obGw']) {
      IF ($_SESSION['Gw']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Gw";
      echo "<button class='".$stil."' name='Gw'>".$text."</button>";
    }
    IF ($_SESSION['obTaille']) {
      IF ($_SESSION['Taille']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Taille";
      echo "<button class='".$stil."' name='Taille'>".$text."</button>";
    }
    IF ($_SESSION['obBewegung']) {
      IF ($_SESSION['Bewegung']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Bewegung";
      echo "<button class='".$stil."' name='Bewegung'>".$text."</button>";
    }
    IF ($_SESSION['obRR']) {
      IF ($_SESSION['RR']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."RR";
      echo "<button class='".$stil."' name='RR'>".$text."</button>";
    }
    IF ($_SESSION['obOAU']) {
      IF ($_SESSION['OAU']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."OAU";
      echo "<button class='".$stil."' name='OAU'>".$text."</button>";
    }
    IF ($_SESSION['obHbA1c']) {
      IF ($_SESSION['HbA1c']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."HbA1c";
      echo "<button class='".$stil."' name='HbA1c'>".$text."</button>";
    }
    IF ($_SESSION['obUzu']) {
      IF ($_SESSION['Uzu']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Uzu";
      echo "<button class='".$stil."' name='Uzu'>".$text."</button>";
    }
    IF ($_SESSION['obHypo']) {
      IF ($_SESSION['Hypo']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Hypo";
      echo "<button class='".$stil."' name='Hypo'>".$text."</button>";
    }
    IF ($_SESSION['obHyper']) {
      IF ($_SESSION['Hyper']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Hyper";
      echo "<button class='".$stil."' name='Hyper'>".$text."</button>";
    }
    IF ($_SESSION['obNeuSt']) {
      IF ($_SESSION['NeuSt']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."NeuSt";
      echo "<button class='".$stil."' name='NeuSt'>".$text."</button>";
    }
    IF ($_SESSION['obFuß']) {
      IF ($_SESSION['Fuß']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Fuß";
      echo "<button class='".$stil."' name='Fuß'>".$text."</button>";
    }
    IF ($_SESSION['obBeruf']) {
      IF ($_SESSION['Beruf']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Beruf";
      echo "<button class='".$stil."' name='Beruf'>".$text."</button>";
    }
    IF ($_SESSION['obAuto']) {
      IF ($_SESSION['Auto']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Auto";
      echo "<button class='".$stil."' name='Auto'>".$text."</button>";
    }
    IF ($_SESSION['obKeto']) {
      IF ($_SESSION['Keto']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Keto";
      echo "<button class='".$stil."' name='Keto'>".$text."</button>";
    }
    IF ($_SESSION['obK+']) {
      IF ($_SESSION['K+']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."K+";
      echo "<button class='".$stil."' name='K+'>".$text."</button>";
    }
    IF ($_SESSION['obChol']) {
      IF ($_SESSION['Chol']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Chol";
      echo "<button class='".$stil."' name='Chol'>".$text."</button>";
    }
    IF ($_SESSION['obHDL']) {
      IF ($_SESSION['HDL']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."HDL";
      echo "<button class='".$stil."' name='HDL'>".$text."</button>";
    }
    IF ($_SESSION['obLDL']) {
      IF ($_SESSION['LDL']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."LDL";
      echo "<button class='".$stil."' name='LDL'>".$text."</button>";
    }
    IF ($_SESSION['obTG']) {
      IF ($_SESSION['TG']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."TG";
      echo "<button class='".$stil."' name='TG'>".$text."</button>";
    }
    IF ($_SESSION['obGGT']) {
      IF ($_SESSION['GGT']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."GGT";
      echo "<button class='".$stil."' name='GGT'>".$text."</button>";
    }
    IF ($_SESSION['obGPT']) {
      IF ($_SESSION['GPT']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."GPT";
      echo "<button class='".$stil."' name='GPT'>".$text."</button>";
    }
    IF ($_SESSION['obFerr']) {
      IF ($_SESSION['Ferr']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Ferr";
      echo "<button class='".$stil."' name='Ferr'>".$text."</button>";
    }
    IF ($_SESSION['obDigo']) {
      IF ($_SESSION['Digo']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Digo";
      echo "<button class='".$stil."' name='Digo'>".$text."</button>";
    }
    IF ($_SESSION['obDigit']) {
      IF ($_SESSION['Digit']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Digit";
      echo "<button class='".$stil."' name='Digit'>".$text."</button>";
    }
    IF ($_SESSION['obUrin']) {
      IF ($_SESSION['Urin']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Urin";
      echo "<button class='".$stil."' name='Urin'>".$text."</button>";
    }
    IF ($_SESSION['obAlb/U']) {
      IF ($_SESSION['Alb/U']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Alb/U";
      echo "<button class='".$stil."' name='Alb/U'>".$text."</button>";
    }
    IF ($_SESSION['obKrea']) {
      IF ($_SESSION['Krea']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Krea";
      echo "<button class='".$stil."' name='Krea'>".$text."</button>";
    }
    IF ($_SESSION['obGFR']) {
      IF ($_SESSION['GFR']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."GFR";
      echo "<button class='".$stil."' name='GFR'>".$text."</button>";
    }
    IF ($_SESSION['obAugen-US']) {
      IF ($_SESSION['Augen-US']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Augen-US";
      echo "<button class='".$stil."' name='Augen-US'>".$text."</button>";
    }
    IF ($_SESSION['obRR-Vgl']) {
      IF ($_SESSION['RR-Vgl']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."RR-Vgl";
      echo "<button class='".$stil."' name='RR-Vgl'>".$text."</button>";
    }
    IF ($_SESSION['obBZ-Vgl']) {
      IF ($_SESSION['BZ-Vgl']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."BZ-Vgl";
      echo "<button class='".$stil."' name='BZ-Vgl'>".$text."</button>";
    }
    IF ($_SESSION['obSchul']) {
      IF ($_SESSION['Schul']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Schul";
      echo "<button class='".$stil."' name='Schul'>".$text."</button>";
    }
    IF ($_SESSION['obTSH']) {
      IF ($_SESSION['TSH']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."TSH";
      echo "<button class='".$stil."' name='TSH'>".$text."</button>";
    }
    IF ($_SESSION['obfT4 [pmol/l]']) {
      IF ($_SESSION['fT4 [pmol/l]']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."fT4 [pmol/l]";
      echo "<button class='".$stil."' name='fT4 [pmol/l]'>".$text."</button>";
    }
    IF ($_SESSION['obfT3']) {
      IF ($_SESSION['fT3']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."fT3";
      echo "<button class='".$stil."' name='fT3'>".$text."</button>";
    }
    IF ($_SESSION['obSchuleintr']) {
      IF ($_SESSION['Schuleintr']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Schuleintr";
      echo "<button class='".$stil."' name='Schuleintr'>".$text."</button>";
    }
    IF ($_SESSION['obHb']) {
      IF ($_SESSION['Hb']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Hb";
      echo "<button class='".$stil."' name='Hb'>".$text."</button>";
    }
    IF ($_SESSION['obVit B12']) {
      IF ($_SESSION['Vit B12']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Vit B12";
      echo "<button class='".$stil."' name='Vit B12'>".$text."</button>";
    }
    IF ($_SESSION['obFolsre']) {
      IF ($_SESSION['Folsre']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Folsre";
      echo "<button class='".$stil."' name='Folsre'>".$text."</button>";
    }
    IF ($_SESSION['obLeuko']) {
      IF ($_SESSION['Leuko']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Leuko";
      echo "<button class='".$stil."' name='Leuko'>".$text."</button>";
    }
    IF ($_SESSION['obCRP']) {
      IF ($_SESSION['CRP']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."CRP";
      echo "<button class='".$stil."' name='CRP'>".$text."</button>";
    }
    IF ($_SESSION['obCK']) {
      IF ($_SESSION['CK']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."CK";
      echo "<button class='".$stil."' name='CK'>".$text."</button>";
    }
    IF ($_SESSION['obA.P.']) {
      IF ($_SESSION['A.P.']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."A.P.";
      echo "<button class='".$stil."' name='A.P.'>".$text."</button>";
    }
    IF ($_SESSION['obCarotis']) {
      IF ($_SESSION['Carotis']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Carotis";
      echo "<button class='".$stil."' name='Carotis'>".$text."</button>";
    }
    IF ($_SESSION['obCar alle']) {
      IF ($_SESSION['Car alle']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Car alle";
      echo "<button class='".$stil."' name='Car alle'>".$text."</button>";
    }
    IF ($_SESSION['obImpf']) {
      IF ($_SESSION['Impf']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Impf";
      echo "<button class='".$stil."' name='Impf'>".$text."</button>";
    }
    IF ($_SESSION['obColo']) {
      IF ($_SESSION['Colo']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Colo";
      echo "<button class='".$stil."' name='Colo'>".$text."</button>";
    }
    IF ($_SESSION['obPros']) {
      IF ($_SESSION['Pros']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Pros";
      echo "<button class='".$stil."' name='Pros'>".$text."</button>";
    }
    IF ($_SESSION['obGyn']) {
      IF ($_SESSION['Gyn']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Gyn";
      echo "<button class='".$stil."' name='Gyn'>".$text."</button>";
    }
    IF ($_SESSION['obgar:']) {
      IF ($_SESSION['gar:']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."gar:";
      echo "<button class='".$stil."' name='gar:'>".$text."</button>";
    }
    IF ($_SESSION['obArzteintrag']) {
      IF ($_SESSION['Arzteintrag']) {
        $stil=cave;
        $text = "&Oslash ";
      } ELSE {
        $stil=unauff;
        $text="";
      }
      $text=$text."Arzteintrag";
      echo "<button class='".$stil."' name='Arzteintrag'>".$text."</button>";
    }
?>

