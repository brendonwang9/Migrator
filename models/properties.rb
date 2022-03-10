def logged_in?() 
    if session[:user_id]
        return true
    else 
        return false
    end
end

def is_admin?() 
    if session[:user_id]
        adminstatus = db_query("select admin from users where user_id = #{session[:user_id]}")[0]["admin"]

        if adminstatus == "t"
            return true
        end
    else
        return false
    end
end

def bookmarked?(property_id)
    sql = "select * from favourites where property_id = #{property_id} and user_id = #{session[:user_id]}"
    result = db_query(sql).first
    if result == nil 
        return false
    else
        return true
    end
end

def db_query(sql, params = []) 
    conn = PG.connect(dbname: 'migrate')
    results = conn.exec_params(sql, params)
    conn.close 
    return results
end

def get_all(database)
    all = db_query("select * from #{database}")

end

def get(database, column, values)
    all_values = db_query("select * from #{database} where #{column} = '#{values}'")
end


def createproperty(results) 
    sql = "insert into properties (property_id, suburb, address, objective, descriptions, image_url, price, bathrooms, bedrooms) values ($1, $2, $3, $4, $5, $6, $7, $8, $9)"
    values = []
    values.push(results["id"])
    values.push(results["addressParts"]["suburb"])
    values.push(results["addressParts"]["displayAddress"])
    values.push(results["objective"])
    values.push(results["description"])
    values.push(results["media"][0]["url"])
    values.push(results["priceDetails"]["displayPrice"])
    values.push(results["bathrooms"])
    values.push(results["bedrooms"])
    db_query(sql, values)
end

def create_favourites(results)
    sql = "insert into favourites (property_id, user_id) values ($1, $2)"
    db_query(sql, results)
end

def create_user(username, password_digest, adminkey)
    sql = "insert into users (username, password_digest, admin) values ($1, $2, $3);"
    db_query(sql, [username, password_digest, adminkey])
end