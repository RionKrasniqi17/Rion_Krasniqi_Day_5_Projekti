# BGT Campus – Day 5 Final Project
**Studenti:** Rion Krasniqi
**Projekti:** Internal Internship – Week III, Day 5
**Teknologjitë:** Flutter, Dart dhe Supabase REST API

## K1 – Plani
Në këtë projekt kam krijuar një aplikacion të thjeshtë për menaxhimin e eventeve të kampusit.
Fillimisht përdoruesi mund të regjistrohet ose të kyçet. Pas kyçjes mund t’i shohë eventet, të shtojë një event të ri dhe t’i menaxhojë vetëm eventet që i ka krijuar vetë. Lista rifreskohet automatikisht çdo 3 sekonda. Kam shtuar edhe filtrimin e eventeve, dark mode, profilin dhe mundësinë për dalje nga llogaria.

## K2 – SQL / RLS
Në skedarin `Day5_SQL.txt` kam vendosur SQL-in për tabelën `events` dhe rregullat e sigurisë RLS.
Kam përdorur:
- `user_id` me `auth.uid()`
- SELECT për leximin e eventeve
- INSERT për përdoruesit e kyçur
- UPDATE vetëm për pronarin
- DELETE vetëm për pronarin

## K3 – Modeli
Në `main.dart` kam krijuar klasën `Event`. Ajo përmban të dhënat kryesore të eventit si id, titulli, data, lokacioni, likes, përdoruesi, autori dhe koha e krijimit.
Kam përdorur edhe `Event.fromJson()` për t’i kthyer të dhënat nga Supabase në objekte Dart. Me `isMine` kontrolloj nëse eventi i përket përdoruesit të kyçur.

## K4 – Leximi
Për leximin e eventeve kam krijuar funksionin `fetchEvents()`, i cili i merr të dhënat nga Supabase REST API.

## K5 – Lista
Eventet i shfaq në `EventsPage` duke përdorur `ListView.builder`.

## K6 – Katër gjendjet
Te lista kam trajtuar katër gjendje:
- loading
- error
- empty
- data
Kështu përdoruesi e kupton çfarë po ndodh gjatë ngarkimit të të dhënave.

## K7 – Login / regjistrim
Kam përdorur Supabase Auth për regjistrim dhe kyçje. Gjithashtu ruaj sesionin e përdoruesit dhe kam mundësinë për logout.

## K8 – Detajet
Në `EventDetailPage` shfaq detajet e eventit:
- titullin
- datën
- lokacionin
- autorin
- numrin e pëlqimeve

## K9 – Forma / validimi
Për shtimin dhe ndryshimin e eventeve kam përdorur `Form` dhe `TextFormField`. Fushat e obligueshme kontrollohen para se të ruhet eventi.

## K10 – Shtimi
Për shtimin e një eventi të ri përdor funksionin `addEvent()` me HTTP POST.

## K11 – Ndryshimi nga pronari
Për ndryshimin e eventit përdor `updateEvent()` me HTTP PATCH. Butoni për ndryshim shfaqet vetëm kur eventi është i përdoruesit të kyçur. Edhe RLS në Supabase e kontrollon këtë.

## K12 – Fshirja nga pronari
Për fshirjen përdor `deleteEvent()` me HTTP DELETE. Para fshirjes kërkoj konfirmim dhe vetëm pronari mund ta fshijë eventin.

## K13 – Lista live
Lista e eventeve rifreskohet automatikisht çdo 3 sekonda me `Timer.periodic`.

## K14 – Filtrimi
Kam shtuar dy `ChoiceChip`:
- Të gjitha
- Të miat
Kur zgjedh “Të miat”, shfaqen vetëm eventet që i kam krijuar unë.

## K15 – Tema / dark mode
Te profili kam shtuar një `SwitchListTile` për ta aktivizuar ose çaktivizuar dark mode.

## K16 – Navigimi me 3+ tab-a
Aplikacioni ka tre pjesë kryesore:
- Home
- Events
- Profile
Për navigim kam përdorur `NavigationBar`.

## K17 – Profili / dalja
Në Profile shfaqet email-i i përdoruesit dhe butoni për dalje nga llogaria.
## K18 – SnackBar / feedback

Kam përdorur `SnackBar` për t’i treguar përdoruesit kur:
- shtohet një event
- ndryshohet një event
- fshihet një event
- ndodh ndonjë gabim
## K19 – README / GitHub
Në këtë README kam përshkruar shkurt funksionet kryesore të projektit dhe mënyrën si e kam ndërtuar.
**GitHub:** https://github.com/RionKrasniqi17/Rion_Krasniqi_Day_5_Projekti

## K20 – ZIP
Për dorëzim kam përgatitur ZIP-in:
`Rion_Krasniqi_Dita5_Projekti.zip`
Brenda tij janë:
- `main.dart`
- `Day5_SQL.txt`
- `README.md`
## Si e testoj projektin në FlutLab
1. Hap projektin Flutter në FlutLab.
2. Te `pubspec.yaml` sigurohem që kam paketën:
```yaml
http: ^1.2.2
```
3. Vendos kodin e `main.dart` te `lib/main.dart`.
4. Ekzekutoj SQL-in nga `Day5_SQL.txt` në Supabase SQL Editor.
5. Nëse dua që regjistrimi të krijojë sesion menjëherë gjatë testimit, te Supabase Auth e mbaj Confirm email të çaktivizuar.
6. Në FlutLab zgjedh Web dhe e nis projektin me Run.
