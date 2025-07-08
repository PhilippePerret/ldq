=begin
Pour lancer ce script :

   ruby test/feature/__test_runner__.rb [options] [dossier]

OPTIONS
-------
  --all   (par défaut) tous les scripts de tous les dossiers
          ou du dossier donné en dernier argument
  --one   Un seul script à choisir
  --dir   Un dossier de test à choisir
  --from  À partir du script…
  --to    Jusqu'au script…
  --same  La même chose que la dernière fois

TODO
----
  * Options --same est à implémenter.

=end
require 'open3'
require 'clir'
APP_FOLDER = File.dirname(File.dirname(__dir__))
FEATURE_FOLDER = File.join(APP_FOLDER, 'test', 'feature')

maybe_folder = ARGV.pop.dup
if maybe_folder && maybe_folder.start_with?('--')
  # Ce n'est pas un dossier, on remet en option
  ARGV << maybe_folder
  test_folder = nil
else
  test_folder = maybe_folder
end
options = {}
ARGV.each do |option|
  if option.start_with?('--')
    options.store(option[2..-1].to_sym, true)
  end
end

# LISTE DES DOSSIERS
test_folders = Dir["#{FEATURE_FOLDER}/*"].select do |path|
  File.directory?(path)
end.map do |path|
  File.basename(path)
end

# Choisir si nécessaire le dossier
if test_folder.nil? || options[:dir]
  # On doit choisir le dossier
  test_folder = Q.select("Dossier des tests à jouer".jaune, test_folders)
end
path_test_folder = File.join(FEATURE_FOLDER, test_folder)

# Choisir le fichier ou le premier ou le dernier
if options[:from] || options[:to] || options[:one]
  test_list = Dir["#{path_test_folder}/*_test.exs"]
  .sort
  .map do |path|
    nfile = File.basename(path, File.extname(path))
    nfile[0..-6] # sans le _test
  end
  if options[:one]
    nfile = Q.select("Fichier à jouer : ".jaune, test_list)
    options.store(:one, nfile)
  elsif options[:from]
    nfile = Q.select("À partir du fichier…".jaune, test_list)
    options.store(:from, nfile)
  end 
  if options[:to]
    # Retirer jusqu'au :from s'il est défini
    test_list =
      if options[:from]
        idtest = test_list.index(options[:from]) + 1
        test_list[idtest..-1]
      else test_list end
    nfile = Q.select("Jusqu'au fichier…".jaune, test_list)
    options.store(:to, nfile)
  end
end

FEATURES_FOLDER = test_folder
ONE_TEST        = options[:one]
FROM_TEST       = options[:from]  # sinon le nom du premier test à jouer
TO_TEST         = options[:to]    # sinon le nom du dernier test à jouer


puts "LANCEMENT DES TESTS DE : #{FEATURES_FOLDER}".bleu
puts "RÉUSSITES".vert + " ET " + "ÉCHECS".rouge
if ONE_TEST
  puts "LE TEST : #{ONE_TEST}".bleu
end
if TO_TEST
  puts "JUSQU'AU TEST : #{TO_TEST}".bleu
  flux_ouvert = true # sera mis à faux si FROM_TEST
end
if FROM_TEST
  puts "DEPUIS LE TEST : #{FROM_TEST}".bleu
  flux_ouvert = false
end

TEMP_COMMAND = 'mix test test/feature/%s/%s_test.exs'
Dir.chdir(APP_FOLDER) do
  tests_folder = "test/feature/#{FEATURES_FOLDER}"
  Dir["#{tests_folder}/*_test.exs"]
  .sort
  .map { |path| File.basename(path, File.extname(path))[0..-6] }
  .each_with_index do |test_name, itest|
    if ONE_TEST 
      next if test_name != ONE_TEST
    elsif flux_ouvert == false && test_name == FROM_TEST
      flux_ouvert = true # et on poursuit
    elsif test_name == TO_TEST
      flux_ouvert = false # et on finit avec celui-là
    elsif flux_ouvert == false
      next
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
      # puts "stdout" + stdout
      # Normalement, la dernière ligne contient le résultat et
      # l'avant dernière ligne les infos sur le temps
      linesout = stdout.strip.split("\n")
      resultat_line   = linesout.pop#.tap{|v| puts "resultat_line: #{v.inspect}"}
      info_time_line  = linesout.pop#.tap{|v| puts "info_time_line: #{v.inspect}"}
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
        entete  = is_succes ? 'Succès' : 'Échec'
        puts "#{entete} de ‘#{test_name}’ : Tests: #{nombre_tests} #{" / Failures : #{nombre_failures}" if is_echec}".send(couleur)
      else
        # <= La sortie n'est pas conforme
        # => on le signale
        puts "Sortie non conforme :".orange
        puts stdout.joint("\n").orange
        puts info_time_line.orange
        puts resultat_line.orange
      end
    else
      # <= Le code de sortie n'est pas 0
      # => Il s'est passé quelque chose
      # puts "status: #{status}"
      puts "Code de sortie #{status.exit}".rouge
      puts "STDERR: #{stderr}".rouge
      break
    end
  end
end