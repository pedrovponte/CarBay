<?php

namespace App\Models;

use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Model;

class FavouriteSeller extends Model
{
    use Notifiable;

    public $timestamps  = false;
    protected $table = 'FavouriteSeller';

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'user1ID', 'user2ID'
    ];
}
