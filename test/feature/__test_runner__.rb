=begin
Pour lancer ce script :

   ruby test/feature/__test_runner__.rb [params] [dossier]

OPTIONS
-------
  --all/-a  (par défaut) tous les scripts de tous les dossiers
            ou du dossier donné en dernier argument
  --one/-o  Un seul script à choisir
  --dir/-d  Un dossier de test à choisir
  --from/-f À partir du script…
  --to/-t   Jusqu'au script…
  --same/-s La même chose que la dernière fois

TODO
----
  * Options --same est à implémenter.

=end
require 'open3'
require 'clir'
APP_FOLDER = File.dirname(File.dirname(__dir__))
FEATURE_FOLDER = File.join(APP_FOLDER, 'test', 'feature')
TEST_SAME_PARAMS_FILE = File.join(FEATURE_FOLDER, '.same_params.msh')
SHORT_OPT_TO_LONG = {'-o' => :one, '-d' => :dir, '-a' => :all, '-f' => :from, '-t' => :to, '-s' => :same}

# Peut-être que le dossier choisi a été mis en dernier argument
maybe_folder = ARGV.pop.dup
if maybe_folder && maybe_folder.start_with?('-')
  # Ce n'est pas un dossier, on remet en option
  ARGV << maybe_folder
  test_folder = nil
else
  test_folder = maybe_folder
end

params = {}
ARGV.each do |option|
  if option.start_with?('--')
    params.store(option[2..-1].to_sym, true)
  elsif option.start_with?('-')
    params.store(SHORT_OPT_TO_LONG[option], true)
  end
end

tests_choices = [
  {name: "Jouer un seul test [option: --one/-o]", value: :one},
  {name: "Jouer les tests d'un dossier [option: --dir/-d]", value: :dir},
  {name: "Jouer les tests d'un dossier de tel test à tel test [option: --from --to/-f -t]", value: :fromto},
  {name: "Jouer les tests d'un dossier à partir d'un test [option: --from/-f]", value: :from},
  {name: "Jouer les tests d'un dossier jusqu'à un test [option: --to/-t]", value: :to},
  {name: "Jouer tous les tests de tous les dossiers", value: :all},
  {name: "Jouer les mêmes que la dernière fois", value: :same}
]

if params.empty?
  case (choix = Q.select("Que veux-tu faire ?".jaune, tests_choices))
  when :fromto then params.merge({from: true, to: true})
  else params.store(choix, true)
  end
end

# LISTE DES DOSSIERS
TEST_FOLDERS = Dir["#{FEATURE_FOLDER}/*"].select do |path|
  File.directory?(path)
end.map do |path|
  File.basename(path)
end


if params[:same] && File.exist?(TEST_SAME_PARAMS_FILE)
  
  # <= Option :same choisi (et fichier dernier test existant)
  # => On reprend les mêmes données
  
  params = Marshal.load(IO.read(TEST_SAME_PARAMS_FILE))
  params.store(:same, true)
  ALL_TESTS = params[:all] == true
  
else
  
  # <= Pas d'option :same
  # => On doit demander les tests à jouer
  
  ALL_TESTS = params[:all] == true

  unless ALL_TESTS
    # Choisir si nécessaire le dossier
    if test_folder.nil? || params[:dir]
      # On doit choisir le dossier
      test_folder = Q.select("Dossier des tests à jouer".jaune, TEST_FOLDERS)
    end
    params.store(:folder, test_folder)

    # Choisir le fichier ou le premier ou le dernier
    path_test_folder = File.join(FEATURE_FOLDER, test_folder)
    if params[:from] || params[:to] || params[:one]
      test_list = Dir["#{path_test_folder}/*_test.exs"]
      .sort
      .map do |path|
        nfile = File.basename(path, File.extname(path))
        nfile[0..-6] # sans le _test
      end
      if params[:one]
        nfile = Q.select("Fichier à jouer : ".jaune, test_list)
        params.store(:one, nfile)
      elsif params[:from]
        nfile = Q.select("À partir du fichier…".jaune, test_list)
        params.store(:from, nfile)
      end 
      if params[:to]
        # Retirer jusqu'au :from s'il est défini
        test_list =
          if params[:from]
            idtest = test_list.index(params[:from]) + 1
            test_list[idtest..-1]
          else test_list end
        nfile = Q.select("Jusqu'au fichier…".jaune, test_list)
        params.store(:to, nfile)
      end
    end
  end

  File.write(TEST_SAME_PARAMS_FILE, Marshal.dump(params))

end #/si (else) option :same

FEATURES_FOLDER = params[:folder]
ONE_TEST        = params[:one]
FROM_TEST       = params[:from]  # sinon le nom du premier test à jouer
TO_TEST         = params[:to]    # sinon le nom du dernier test à jouer


# === Message de début ===
puts "LANCEMENT DES TESTS DE : #{FEATURES_FOLDER}".bleu
if ALL_TESTS
  puts "TOUS LES TESTS".bleu
else
  if ONE_TEST
    puts "LE TEST : #{ONE_TEST}".bleu
  end
  if TO_TEST
    puts "JUSQU'AU TEST : #{TO_TEST}".bleu
  end
  if FROM_TEST
    puts "DEPUIS LE TEST : #{FROM_TEST}".bleu
  end
end

TEMP_COMMAND = 'mix test test/feature/%s/%s_test.exs'

# Utilisé par la méthode suivante pour vérifier le retour du test
# Note : parfois, le test peut renvoyer un code autre que 0 mais
# que ce soit une fin normale, avec un test qui a échoué.
def check_fin_test_normale(stdout, test_name)
  # puts "stdout" + stdout
  # Normalement, la dernière ligne contient le résultat et
  # l'avant dernière ligne les infos sur le temps
  linesout = stdout.strip.split("\n")
  resultat_line  = linesout.pop
  info_time_line = linesout.pop
  if info_time_line.start_with?("Finished in")
    # <= La sortie se termine bien avec la fin du test
    # => Tout s'est bien passé, même les erreurs
    # On analyse le résultat
    res = resultat_line.strip.scan(/([0-9]+) test.+([0-9]+) failures?/)
    res = res[0]
    nombre_tests, nombre_failures = res.map{|n|n.to_i}
    is_succes = nombre_failures == 0
    is_echec  = !is_succes
    couleur = is_succes ? :vert : :rouge
    entete  = is_succes ? 'Succès' : 'Échec (cf. ci-dessus)'
    puts stdout.rouge if is_echec # Pour écrire l'échec
    puts "#{entete} de ‘#{test_name}’ : Tests: #{nombre_tests} #{" / Failures : #{nombre_failures}" if is_echec}".send(couleur)

    return true
  else
    return false
  end
end

# Joue les tests voulus du dossier +folder_name+ avec les
# paramètres +params+ (qui dit par exemple qu'il faut s'arrêter à la
# première erreur)
def run_tests_in_folder(folder_name, params)
  if TO_TEST
    flux_ouvert = true # sera mis à faux si FROM_TEST
  end
  if FROM_TEST
    flux_ouvert = false
  end
  tests_folder = "test/feature/#{folder_name}"
  Dir["#{tests_folder}/*_test.exs"]
  .sort
  .map { |path| File.basename(path, File.extname(path))[0..-6] }
  .each_with_index do |test_name, itest|
    unless ALL_TESTS
      if ONE_TEST 
        next if test_name != ONE_TEST
      elsif flux_ouvert == false && test_name == FROM_TEST
        flux_ouvert = true # et on poursuit
      elsif test_name == TO_TEST
        flux_ouvert = false # et on finit avec celui-là
      elsif flux_ouvert == false
        next
      end
    end

    # puts "Le test #{test_name.inspect} passe".bleu
    # next # ON NE FAIT RIEN POUR LE MOMENT

    # ================================= #
    # ===            TEST           === #
    # ================================= #
    puts "Lancement du test #{test_name.inspect}…".bleu
    command = TEMP_COMMAND % [FEATURES_FOLDER, test_name]
    stdout, stderr, status = Open3.capture3(command)


    if status.exitstatus == 0
      unless check_fin_test_normale(stdout, test_name)
        # <= La sortie n'est pas conforme
        # => on le signale
        puts "Sortie non conforme :".orange
        puts stdout.joint("\n").orange
        puts info_time_line.orange
        puts resultat_line.orange
      end
    else
      # <= Le code de sortie n'est pas 0
      # => Il s'est peut-être passé quelque chose. Mais ça n'est pas
      #    toujours le cas, donc il faut vérifier le résultat
      # puts "status: #{status}"
      unless check_fin_test_normale(stdout, test_name)
        puts "Code de sortie #{status.exitstatus}".rouge
        puts "STDERR\n------\n#{stderr}".rouge
        puts "STDOUT\n------\n#{stdout}".gris
        break
      end
    end
  end

end

Dir.chdir(APP_FOLDER) do
  if ALL_TESTS
    TEST_FOLDERS.each do |folder_name|
      run_tests_in_folder(folder_name, params)
    end
  else
    run_tests_in_folder(FEATURES_FOLDER, params)
  end
end