#!/bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi
echo "DB ciblée: $($PSQL "SELECT current_database()")"

# Do not change code above this line. Use the PSQL variable above to query your database.

# Clean reset matches
$PSQL "TRUNCATE games RESTART IDENTITY;"

# Insert each team one time
tail -n +2 games.csv | while IFS=',' read YEAR ROUND WIN OPP WG OG
do
  WIN=$(echo "$WIN" | sed 's/\r$//')
  OPP=$(echo "$OPP" | sed 's/\r$//')
  $PSQL "INSERT INTO teams(name) VALUES('$WIN') ON CONFLICT (name) DO NOTHING;"
  $PSQL "INSERT INTO teams(name) VALUES('$OPP') ON CONFLICT (name) DO NOTHING;"
done


# Insert all matches
tail -n +2 games.csv | while IFS=',' read YEAR ROUND WIN OPP WG OG
do
  ROUND=$(echo "$ROUND" | sed 's/\r$//')
  WIN=$(echo "$WIN" | sed 's/\r$//')
  OPP=$(echo "$OPP" | sed 's/\r$//')
  WIN_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WIN'")
  OPP_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPP'")
  echo "Match: $WIN vs $OPP — IDs: $WIN_ID vs $OPP_ID"

  $PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
  VALUES ($YEAR, '$ROUND',
    (SELECT team_id FROM teams WHERE name='$WIN'),
    (SELECT team_id FROM teams WHERE name='$OPP'),
    $WG, $OG);"
done

