import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../../../../core/models/spotify_track.dart';

class SpotifySearchSheet extends StatefulWidget {
  const SpotifySearchSheet({super.key});

  @override
  State<SpotifySearchSheet> createState() => _SpotifySearchSheetState();
}

class _SpotifySearchSheetState extends State<SpotifySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<SpotifyTrack> _searchResults = [];
  bool _isLoading = false;
  String? _currentlyPlayingId;
  String? _accessToken;

  // Spotify API credentials — from developers.spotify.com
  final String _clientId = 'ef817e78f1064f65834595c2d18780d7';
  final String _clientSecret = '6b1dd86177e64da78d4016ff8dc158a2';

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _getAccessToken() async {
    if (_accessToken != null) return;

    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
      } else {
        
      }
    } catch (e) {
      
    }
  }

  Future<void> _searchTracks(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    await _getAccessToken();

    if (_accessToken == null) {
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please configure Spotify API Keys')),
        );
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track&limit=20'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List tracks = data['tracks']['items'];
        setState(() {
          _searchResults = tracks.map((t) => SpotifyTrack.fromJson(t)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _togglePreview(SpotifyTrack track) async {
    if (track.previewUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview available for this track')),
      );
      return;
    }

    if (_currentlyPlayingId == track.id) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingId = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(track.previewUrl!);
      await _audioPlayer.play();
      setState(() => _currentlyPlayingId = track.id);
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _currentlyPlayingId = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Add Music',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for a song...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
                onSubmitted: _searchTracks,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final track = _searchResults[index];
                      final isPlaying = _currentlyPlayingId == track.id;

                      return InkWell(
                        onTap: () => _togglePreview(track),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              // Album Art
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: track.albumArtUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (isPlaying)
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.pause, color: Colors.white, size: 24),
                                    )
                                  else if (track.previewUrl != null)
                                    const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                                ],
                              ),
                              const SizedBox(width: 16),
                              
                              // Track Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.name,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      track.artist,
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Add Button
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  foregroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  _audioPlayer.stop();
                                  Navigator.pop(context, track);
                                },
                                child: Text(
                                  'Add',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
}
